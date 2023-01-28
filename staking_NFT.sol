// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "https://github.com/sueun-dev/staking_contract/blob/main/ERC20_staking";
import "https://github.com/sueun-dev/staking_contract/blob/main/ERC721_staking.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTStaking is Ownable, IERC721Receiver {

  struct Stake {
    address owner;
    uint24 tokenId;
    uint48 timestamp;
  }

  event NFTStaked(address owner, uint256 tokenId, uint256 value);
  event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
  event Claimed(address owner, uint256 amount);

  GOMZCUB_NFT nft;
  ERC20_staking token;

  mapping(uint256 => Stake) public vault; 

  constructor(GOMZCUB_NFT _nft, ERC20_staking _token) { 
      
    nft = GOMZCUB_NFT(_nft);
    token = _token;
  }

  function stake(uint256[] calldata tokenIds) external {
    uint256 tokenId;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      require(nft.ownerOf(tokenId) == msg.sender, "not your token");

      require(vault[tokenId].tokenId == 0, "already staked");
      nft.transferFrom(msg.sender, address(this), tokenId);
      emit NFTStaked(msg.sender, tokenId, block.timestamp);

      vault[tokenId] = Stake({
        owner: msg.sender,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });
    }
  }
  //require approval
  function claim(uint256[] calldata tokenIds) external {
    _claim(msg.sender, tokenIds, false);
  }   

  function unstake(uint256[] calldata tokenIds) external {
    _claim(msg.sender, tokenIds, true);
  }

  function _unstakeMany(address account, uint256[] calldata tokenIds) internal {
    uint256 tokenId;

    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == msg.sender, "not an owner");
      delete vault[tokenId];
      emit NFTUnstaked(account, tokenId, block.timestamp);
      nft.transferFrom(address(this), account, tokenId);
    }
  }

  function _claim(address account, uint256[] calldata tokenIds, bool _unstake) internal {
    uint256 tokenId;
    uint256 earned = 0;
    uint256 rewardmath = 0;

    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == account, "not an owner");
      uint256 stakedAt = staked.timestamp;
      //하루에 시작 5이더
      uint256 duration = block.timestamp - stakedAt;
      //지나온 시간에 따른 보상 변화
      //86400 = 1 day
      //864000 = 10 days
      //864000 * 5 = 50 days
      //864000 * 10 = 100 days
      if (duration < 864000) {
        rewardmath = 5 ether * duration / 86400;
      } else if (duration >= 864000 && duration < 864000 * 5) {
        rewardmath = 8 ether * duration / 86400;
      } else if (duration >= 864000 * 5 && duration < 8640000) {
        rewardmath = 16 ether * duration / 86400;
      } else {
        rewardmath = 40 ether * duration / 86400;
      }
      earned += rewardmath;
      //timestamp
      vault[tokenId] = Stake({
        owner: account,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });
    }

    if (rewardmath > 0) {
      token.mint(account, earned);
    }

    if (_unstake) {
      _unstakeMany(account, tokenIds);
    }

    emit Claimed(account, earned);
  }


     function earningInfo(address account, uint256[] calldata tokenIds) external view returns (uint256[1] memory info) {
        uint256 tokenId;
        uint256 earned = 0;
        uint256 rewardmath = 0;

        for (uint i = 0; i < tokenIds.length; i++) {
          tokenId = tokenIds[i];
          Stake memory staked = vault[tokenId];
          require(staked.owner == account, "not an owner");
          uint256 stakedAt = staked.timestamp;
          //start 5 ether per day
          uint256 duration = block.timestamp - stakedAt;
          //지나온 시간에 따른 보상 변화
          //86400 = 1 day
          //864000 = 10 days
          //864000 * 5 = 50 days
          //864000 * 10 = 100 days
          if (duration < 864000) {
            rewardmath = 5 ether * duration / 86400;
          } else if (duration >= 864000 && duration < 864000 * 5) {
            rewardmath = 8 ether * duration / 86400;
          } else if (duration >= 864000 * 5 && duration < 8640000) {
            rewardmath = 16 ether * duration / 86400;
          } else {
            rewardmath = 40 ether * duration / 86400;
          }
          earned += rewardmath;
          //timestamp

        if (earned > 0) {
            return [earned];
        }
      }   
     }





  function balanceOf(address account) public view returns (uint256) {
    uint256 balance = 0;
    uint256 supply = nft.totalSupply();
    for(uint i = 1; i <= supply; i++) {
      if (vault[i].owner == account) {
        balance += 1;
      }
    }
    return balance;
  }

  function tokensOfOwner(address account) public view returns (uint256[] memory ownerTokens) {

    uint256 supply = nft.totalSupply();
    //[]() 에서 ()는 배열의 요소의 개수 ex [](3) 이면 0번째 배열에 3개 들어감
    uint256[] memory tmp = new uint256[](supply);

    uint256 index = 0;
    for(uint tokenId = 0; tokenId <= supply; tokenId++) {
      if (vault[tokenId].owner == account) {
        tmp[index] = vault[tokenId].tokenId;
        index +=1;
      }
    }

    uint256[] memory tokens = new uint256[](index);
    for(uint i = 0; i < index; i++) {
      tokens[i] = tmp[i];
    }

    return tokens;
  }
  //토큰을 수신할수 있는 컨트렉트. 즉 토큰을 받을 수 있는 컨트렉트
  //토큰을 수신할때 무조건 호출됌
  function onERC721Received(
        //address는 토큰을 수신하는 주소
        address,
        //address from은 토큰을 보내는 주소
        address from,
        //uint256은 토큰 아이디 
        uint256,
        //bytes calldata는 토큰을 전송할때 전달되는 데이터
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Not Correct onERC721");
      return IERC721Receiver.onERC721Received.selector;
    }
  
}
