// SPDX-License-Identifier: MIT
// All created by Sueun Cho
pragma solidity ^0.8.4;

import "https://github.com/sueun-dev/ERC721A_GOMZ/blob/main/contracts/ERC721A.sol";
import "https://github.com/sueun-dev/staking_contract/blob/main/ERC20_staking";
import "./whitelist.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";

contract GOMZCUB_NFT is ERC721A, Ownable, ReentrancyGuard, Whitelist{

    struct TokenInfo {
        //Name paytoken, costvalue
        IERC20 paytoken;
        uint256 costvalue;
    }

    TokenInfo[] public AllowedCrypto;

    uint256 public DEV_MAX_SUPPLY = 10;
    uint256 public WL_MAX_SUPPLY = 20;
    uint256 public MAX_SUPPLY = 3000;

    uint256 public PRICE_PER_ETH = 0.01 ether;
    uint256 public WL_PRICE_PER_ETH = 0.03 ether;

    string private _baseTokenURI;
    string public notRevealedUri;

    uint256 public constant maxPurchase = 5;

    bool public isSale = false;
    bool public WLisSale = false;
    bool public revealed = false;
    bool public TokenisSale = false;

    modifier onlyWhiteList() {
        require(isWhitelisted(msg.sender) == true, "You are not WL");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(string memory baseTokenURI, string memory _initNotRevealedUri) ERC721A("NFT_NAME", "NFT_SYMBOL") {
        _baseTokenURI = baseTokenURI;
        setNotRevealedURI(_initNotRevealedUri);
    }

     function addCurrency(IERC20 _paytoken,uint256 _costvalue) public onlyOwner {
        AllowedCrypto.push(
            TokenInfo({
                paytoken: _paytoken,
                costvalue: _costvalue
            })
        );
    }

    function mintByETH(uint256 quantity) external payable {
        require(isSale, "Public sale is NOT start");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(quantity + _numberMinted(msg.sender) <= 2, "Exceeded the limit per wallet");
        require(quantity <= maxPurchase, "Can only mint 5 NFT at a time");
        //require(msg.value >= (PRICE_PER_ETH * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function WLmintByETH(uint256 quantity) external payable onlyWhiteList{
        require(WLisSale, "Not Start");
        require(totalSupply() + quantity <= WL_MAX_SUPPLY, "Not enough tokens left");
        require(quantity <= maxPurchase, "Can only mint 5 NFT at a time");
        require(msg.value >= (WL_PRICE_PER_ETH * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function developerPreMint(uint256 quantity) external payable onlyOwner {
        require(!isSale, "Developer Minting should be Not Start public minting");
        require(!WLisSale, "Developer Minting should be Not Start WL minting");
        require(totalSupply() + quantity <= DEV_MAX_SUPPLY, "Not enough tokens left"); // 토큰 600개 제한
        _safeMint(msg.sender, quantity);
    }
    //setTokenArray start "0"
    function mintpid(address _to, uint256 quantity, uint256 _setTokenArray) external payable {
        uint256 costval;
        TokenInfo storage tokens = AllowedCrypto[_setTokenArray];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        costval = tokens.costvalue;
        require(TokenisSale, "Token Sale has not started");
        require(quantity > 0, "Buy over 0");
        require(quantity <= maxPurchase, "Over mint");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Over mint");
        require(paytoken.transferFrom(msg.sender, address(this), costval * quantity));
        _safeMint(_to, quantity);
    }

    function withdraw() external onlyOwner nonReentrant{
        payable(owner()).transfer(address(this).balance);
    }


    function transferTokenToOnwer(uint256 _setTokenArray) payable public onlyOwner nonReentrant{
        TokenInfo storage tokens = AllowedCrypto[_setTokenArray];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        paytoken.transfer(address(msg.sender), paytoken.balanceOf(address(this)));
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {

        if(revealed) { 
            return notRevealedUri;
        }

        return _baseTokenURI;
    }

    function setSale() public onlyOwner {
        isSale = !isSale;
    }

    function WLwsetSale() public onlyOwner {
        WLisSale = !WLisSale;
    }

    function TokenSale() public onlyOwner {
        TokenisSale = !TokenisSale;
    }


    ////NFT air drop test
    //첫번째 매개변수에는 유저의 지갑 주소가 들어가야 함. (필수)
    //두번째 매개변수에는 할당된 유저의 지갑에 몇개의 NFT를 쏠것인지를 넣어야 함. (필수)
    //고로 for문이 작동해야 하며 mint의 과정과 같게 진행하면 될것같다.
    //또한 isSale과 WLisSale이 시작 전에 air drop을 통해 진행해야 한다 (간단한 유저와의 약속) 암묵적인 룰
    //amounts[indx] + totalSupply() <= MAX_SUPPY

    function batchTransfer(address[] calldata tokenHolders, uint256[] calldata amounts) external onlyOwner
    {
        require(tokenHolders.length == amounts.length, "Invalid input parameters");
        require(!isSale, "Developer Minting should be Not Start public minting");
        require(!WLisSale, "Developer Minting should be Not Start WL minting");
        
        for(uint256 indx = 0; indx < tokenHolders.length; indx++) {
            require(totalSupply() + amounts[indx] <= MAX_SUPPLY, "Not enough tokens left");
            _safeMint(tokenHolders[indx], amounts[indx]);
        }
    }


}