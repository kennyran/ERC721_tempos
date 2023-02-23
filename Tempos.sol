// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Tempos is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    // ======// Variables //======

    // Maximum amount in existance
    uint256 public constant MAX_SUPPLY = 1000;

    // Price of each NFT Mint
    uint256 public constant PRICE = 0.12 ether;

    // Toggle sale on and off
    bool public saleIsActive = false;
    string private _baseTokenURI;

    // Tempos watch art reveal
    bool public revealed = false;

    // Whitelist variables
    bool public onlyWhitelisted = true;
    address[] public whitelistedAddresses;
    mapping(address => uint256) public addressMintedBalance;
    mapping(address => bool) public whitelisted;

    // ======// Constructor //======
    constructor() ERC721("TEMPOS", "TEMPOS") {}

    // ======// Functions //======

    // Max amount wallet can mint per transaction
    function getMaxAmount() public view returns (uint256) {
        require(
            _tokenSupply.current() < MAX_SUPPLY,
            "Sale has ended, no more items left to mint."
        );

        return 10; // 10 mint max per wallet & transaction
    }

    // Price of mint
    function currentPrice() public view returns (uint256) {
        uint256 totalMinted = _tokenSupply.current();

        if (totalMinted <= 1000) {
            return PRICE;
        }
    }

    // Minting function
    function mint(uint256 _numberOfTokens) public payable {
        require(saleIsActive, "TEMPOS is not for sale yet!");

        uint256 mintIndex = _tokenSupply.current(); // Start IDs at 1
        require(mintIndex <= MAX_SUPPLY, "Tempos supply is sold out!");

        uint256 mintPrice = currentPrice();
        require(msg.value >= mintPrice, "Not enough ETH to buy a TEMPOS!");
        require(
            _numberOfTokens > 0,
            "You cannot mint 0 TEMPOS, please increase to 1 or more"
        );
        require(
            _numberOfTokens <= getMaxAmount(),
            "You are not allowed to mint this many TEMPOS at once."
        );

        // for whitelisted users mint
        if (msg.sender != owner()) {
            if (onlyWhitelisted == true) {
                require(verifyUser(msg.sender), "User is not whitelisted");
                uint256 ownerMintedCount = addressMintedBalance[msg.sender];
                require(ownerMintedCount + _numberOfTokens <= getMaxAmount());
            }

            require(
                msg.value >= PRICE * _numberOfTokens,
                "Not enough ETH to buy a TEMPOS"
            );
        }

        // Mint
        for (uint256 i = 0; i < _numberOfTokens; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, _tokenSupply.current());
        }
    }

    // Reveal artwork
    function reveal() public onlyOwner {
        revealed = true;
    }

    // Remaining NFT's to be minted
    function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - _tokenSupply.current();
    }

    // Amount of NFT's currently minted
    function tokenSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    // Add addresses to whitelist
    function whitelistUsers(address[] memory _whitelist) public onlyOwner {
        for (uint256 i = 0; i < _whitelist.length; i++) {
            address _user = _whitelist[i];
            whitelisted[_user] = true;
        }

        whitelistedAddresses = _whitelist;
    }

    // view Whitelisted addresses
    function verifyUser(address _whitelistedAddress)
        public
        view
        returns (bool)
    {
        bool userIsWhitelisted = whitelisted[_whitelistedAddress];
        return userIsWhitelisted;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        _baseTokenURI = _baseURI;
    }

    // Set sale to active to begin minting
    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // Withdraw ETH balance from Contract to Owner (account that deployed the contract)
    function withdrawBalance() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
