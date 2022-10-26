// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IConstantFlowAgreementV1 } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import { ISuperfluidToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

/*
* Minimal ERC-721 representation of an outgoing flow.
* To be deployed specifically for a token, receiver, minFlowrate
*/
contract FlowSender721 {

    /// thrown by methods not available, e.g. transfer
    error NOT_AVAILABLE();
    
    /// thrown when looking up a token or flow which doesn't exist
    error NOT_EXISTS();

    /// thrown when trying to mint to the zero address
    error ZERO_ADDRESS();

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    IConstantFlowAgreementV1 immutable public cfaV1;
    ISuperfluidToken immutable public token;
    address immutable public receiver;
    int96 immutable public minFlowrate;

    constructor(address cfa_, address token_, address receiver_, int96 minFlowrate_) {
        cfaV1 = IConstantFlowAgreementV1(cfa_);
        token = ISuperfluidToken(token_);
        receiver = receiver_;
        minFlowrate = minFlowrate_;
    }

    // ============= ERC721 interface =============

    // interprets the id as sender address, returns itself if flow with minFlowrate exists, reverts otherwise
    function ownerOf(uint256 id) public view virtual returns (address owner) {
        if (! _hasToken(address(uint160(id)))) revert NOT_EXISTS();
        return address(uint160(id));
    }

    // returns 1 if a flow with minFlowrate exists, 0 otherwise
    function balanceOf(address owner) public view virtual returns (uint256) {
        if(owner == address(0)) revert ZERO_ADDRESS();
        return _hasToken(owner) ? 1 : 0;
    }

    // ERC165 Interface Detection
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // Interface ID for ERC165
            interfaceId == 0x80ac58cd; // Interface ID for ERC721
    }

    function approve(address /*spender*/, uint256 /*id*/) public pure {
        revert NOT_AVAILABLE();
    }

    function setApprovalForAll(address /*operator*/, bool /*approved*/) public pure {
        revert NOT_AVAILABLE();
    }

    function transferFrom(address /*from*/, address /*to*/, uint256 /*id*/) public pure {
        revert NOT_AVAILABLE();
    }

    function safeTransferFrom(address /*from*/, address /*to*/, uint256 /*id*/) public pure {
        revert NOT_AVAILABLE();
    }

    function safeTransferFrom(address /*from*/, address /*to*/, uint256 /*id*/, bytes calldata /*data*/) public pure {
        revert NOT_AVAILABLE();
    }

    // ============= private interface =============

    function _hasToken(address sender) internal view returns(bool) {
        (,int96 fr,,) = cfaV1.getFlow(token, sender, receiver);
        return fr >= minFlowrate;
    }
}