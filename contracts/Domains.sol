// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// helper funcs
import { StringUtils } from "./libraries/StringUtils.sol";
import {Base64} from "./libraries/Base64.sol";

import "hardhat/console.sol";

contract Domains is ERC721URIStorage {
  error Unauthorized();
  error AlreadyRegistered();
  error InvalidName(string name);

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  string public tld;
	
	// We'll be storing our NFT images on chain as SVGs
  string svgPartOne = '<svg viewBox="3.051 -291.781 270.089 267.51" xmlns="http://www.w3.org/2000/svg" xmlns:bx="https://boxy-svg.com"><defs><linearGradient id="paint0_linear_2_14" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse" gradientTransform="matrix(1, 0, 0, 1, 3.359108, -293.594933)"><stop stop-color="#F8FAB8"/><stop offset="1" stop-color="#DC8989" stop-opacity="0.99"/></linearGradient><style bx:fonts="Abel">@import url(https://fonts.googleapis.com/css2?family=Abel%3Aital%2Cwght%400%2C400&amp;display=swap);</style></defs><path d="M 3.359 -293.595 L 273.359 -293.595 L 273.359 -23.595 L 3.359 -23.595 L 3.359 -293.595 Z" fill="url(#paint0_linear_2_14)"/><text style="fill: rgb(104, 89, 89); font-family: Abel; font-size: 36px; text-transform: uppercase; white-space: pre;" x="38.345" y="-83.238">';
  string svgPartTwo = '</text><g transform="matrix(0.02095, 0, 0, -0.022621, 12.704104, -177.200012)" fill="#000000" stroke="none" style=""><path d="M944 4044 c3 -22 13 -156 22 -299 l17 -260 765 -767 765 -766 -36 -7 c-50 -10 -97 -63 -97 -110 0 -52 19 -83 66 -106 38 -18 49 -19 79 -9 40 13 85 62 85 93 0 15 39 61 118 140 l118 118 240 -240 c194 -194 243 -247 252 -280 33 -107 166 -119 215 -19 15 31 16 44 7 77 -12 44 -53 81 -92 81 -17 0 -86 62 -268 245 l-244 246 119 119 c87 87 126 120 150 124 90 17 117 139 44 200 -63 54 -155 20 -181 -65 l-12 -40 -765 764 -766 765 -235 11 c-129 6 -266 14 -303 17 l-68 6 5 -38z m385 -8 l213 -13 696 -696 c557 -557 694 -699 684 -709 -10 -10 -152 127 -705 680 l-693 693 -259 14 c-143 8 -260 13 -261 12 0 -1 7 -116 17 -256 l18 -255 693 -693 c553 -553 690 -695 680 -705 -10 -10 -152 127 -709 684 l-696 696 -18 268 c-10 148 -18 275 -19 282 0 16 80 15 359 -2z m1932 -1435 c53 -54 28 -143 -45 -156 -47 -9 -614 -574 -633 -632 -17 -48 -46 -73 -89 -73 -44 0 -83 35 -90 81 -5 28 -1 41 21 67 18 21 36 32 53 32 22 0 85 58 329 302 224 224 303 309 303 326 0 35 52 82 90 82 22 0 41 -9 61 -29z m-254 -43 l53 -53 -262 -262 c-145 -145 -268 -263 -273 -263 -6 0 -33 22 -60 50 l-49 50 264 265 c146 146 267 265 269 265 3 0 29 -24 58 -52z m6 -466 l67 -68 -38 -37 -38 -37 -69 70 -69 70 34 35 c19 19 37 35 40 35 3 0 36 -31 73 -68z m448 -422 c31 0 75 -40 81 -74 6 -32 -15 -82 -41 -95 -22 -12 -70 -14 -96 -5 -18 7 -45 55 -45 81 0 10 -22 41 -50 68 l-50 49 37 38 37 38 51 -50 c34 -34 59 -50 76 -50z" style="fill: rgb(73, 73, 73);"/></g></svg>';

  mapping(string => address) public domains;
  mapping(string => string) public records;
  mapping (uint => string) public names;

  address payable public owner;


  constructor(string memory _tld) ERC721 ("Berserk Name Service", "BNS") payable {
    owner = payable(msg.sender);
    tld = _tld;
    console.log("%s name service deployed", _tld);
  }

  function register(string calldata name) public payable {
    if (domains[name] != address(0)) revert AlreadyRegistered();
    if (!valid(name)) revert InvalidName(name);

    uint256 _price = this.price(name);
    require(msg.value >= _price, "Not enough Matic paid");
		
		// Combine the name passed into the function  with the TLD
    string memory _name = string(abi.encodePacked(name, ".", tld));
		// Create the SVG (image) for the NFT with the name
    string memory finalSvg = string(abi.encodePacked(svgPartOne, _name, svgPartTwo));
    uint256 newRecordId = _tokenIds.current();
  	uint256 length = StringUtils.strlen(name);
		string memory strLen = Strings.toString(length);

    console.log("Registering %s.%s on the contract with tokenID %d", name, tld, newRecordId);

		// Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64
    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "',
            _name,
            '", "description": "A domain on the Berserk name service", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(finalSvg)),
            '","length":"',
            strLen,
            '"}'
          )
        )
      )
    );

    string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));

    _safeMint(msg.sender, newRecordId);
    _setTokenURI(newRecordId, finalTokenUri);
    domains[name] = msg.sender;
    names[newRecordId] = name;

    _tokenIds.increment();
  }
		// This function will give us the price of a domain based on length
    function price(string calldata name) public pure returns(uint) {
        uint len = StringUtils.strlen(name);
        require(len > 0);
        if (len == 3) {
          return 0.5 * 10**17; // 5 MATIC = 5 000 000 000 000 000 000 (18 decimals). We're going with 0.5 Matic cause the faucets don't give a lot
        } else if (len == 4) {
	        return 0.3 * 10**17; // To charge smaller amounts, reduce the decimals. This is 0.3
        } else {
	        return 0.1 * 10**17;
        }
    }

    function getAddress(string calldata name) public view returns (address) {
				// Check that the owner is the transaction sender
        return domains[name];
    }

    function setRecord(string calldata name, string calldata record) public {
				// Check that the owner is the transaction sender
        if (msg.sender != domains[name]) revert Unauthorized();
        records[name] = record;
    }

    function getRecord(string calldata name) public view returns(string memory) {
        return records[name];
    }

    modifier onlyOwner() {
      require(isOwner());
      _;
    }

    function isOwner() public view returns (bool) {
      return msg.sender == owner;
    }

    function withdraw() public onlyOwner {
      uint amount = address(this).balance;
      
      (bool success, ) = msg.sender.call{value: amount}("");
      require(success, "Failed to withdraw Matic");
    } 

    // Add this anywhere in your contract body
    function getAllNames() public view returns (string[] memory) {
      console.log("Getting all names from contract");
      string[] memory allNames = new string[](_tokenIds.current());
      for (uint i = 0; i < _tokenIds.current(); i++) {
        allNames[i] = names[i];
        console.log("Name for token %d is %s", i, allNames[i]);
      }

      return allNames;
    }

    // domain validation
    function valid(string calldata name) public pure returns(bool) {
      return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 10;
    }
}