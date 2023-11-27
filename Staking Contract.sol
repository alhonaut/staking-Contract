// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Staking {

    IERC20 immutable token; // we use 'immutable' because don't want somebody to change this object and it can be once only
    IERC721 immutable nft; // we use 'immutable' because don't want somebody to change this object and it can be once only

    mapping(address => mapping(uint256 => uint256)) stakes; // address => tokenId of NFT => timestamp of NFT creation

    constructor(address _nft, address _token) {
        token = IERC20(_token);
        nft = IERC721(_nft);
    }

    function calculateRate(uint256 _tokenId) private view returns(uint256) {
        uint256 time = stakes[msg.sender][_tokenId];
        if (block.timestamp - time < 1 minutes) {
            return 0;
        }
        else {
            return (block.timestamp - time / 1 minutes) * (10 ** 18); // return price for each minute of staking in wei
        }
    }
    
    function stake(uint256 _tokenId) public {
        require(nft.ownerOf(_tokenId) == msg.sender, "You are not a owner of this NFT.");
        stakes[msg.sender][_tokenId] = block.timestamp; // we write time of creation NFTs for users
        nft.safeTransferFrom(msg.sender, address(this), _tokenId, ""); // we transfer nft from msg.sender to our contract address while it staking
    }

    function unstake(uint256 _tokenId) public {
        require(nft.ownerOf(_tokenId) == msg.sender, "You are not a owner of this NFT.");
        require(stakes[msg.sender][_tokenId] < 1 days, "The staking period has not yet passed");
        nft.safeTransferFrom(address(this), msg.sender, _tokenId, ""); // we tranfer nft back to owner
        delete stakes[msg.sender][_tokenId]; // after unstaking we delete tokenId of nft from our mapping
        
        uint256 stake_reward = calculateReward(_tokenId); // reward for staking
        token.transfer(msg.sender, stake_reward); // we transfer money to user


    }

    function calculateReward(uint256 _tokenId) public view returns(uint256 reward) {
        require(stakes[msg.sender][_tokenId] > 0, "NFT has not been staked.");
        reward = calculateRate(_tokenId);
        return reward;
    }
}