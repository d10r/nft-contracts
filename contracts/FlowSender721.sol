// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IConstantFlowAgreementV1 } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import { ISuperfluidToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

/*
* Minimal ERC-721 representation of an outgoing flow.
* To be deployed specifically for a token, receiver
*/
contract FlowSender721 {

    /// thrown by methods not available, e.g. transfer
    error NOT_AVAILABLE();
    
    /// thrown when looking up a token or flow which doesn't exist
    error NOT_EXISTS();

    /// thrown when trying to mint to the zero address
    error ZERO_ADDRESS();

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    IConstantFlowAgreementV1 immutable public CFAv1;
    ISuperfluidToken immutable public TOKEN;
    address immutable public RECEIVER;

    constructor(address cfa_, address token_, address receiver_) {
        CFAv1 = IConstantFlowAgreementV1(cfa_);
        TOKEN = ISuperfluidToken(token_);
        RECEIVER = receiver_;
    }

    // ============= ERC721 interface =============

    // interprets the id as sender address and minFlowrate concatenated (packed)
    // returns sender address if such a flow exists, reverts otherwise
    function ownerOf(uint256 id) public view virtual returns (address owner) {
        (address sender, int96 minFr) = decodeId(id);
        if (_getFlowrate(sender) >= minFr) {
            return sender;
        }
        revert NOT_EXISTS();
    }

    // returns the flowrate (0 if no flow) from the sender
    function balanceOf(address owner) public view virtual returns (uint256) {
        if(owner == address(0)) revert ZERO_ADDRESS();
        return uint256(uint96(_getFlowrate(owner)));
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

    function decodeId(uint256 id) public pure returns(address addr, int96 minFr) {
        addr = address(uint160(bytes20(bytes32(id))));
        minFr = int96(uint96(bytes12(bytes32(id) << 160)));
    }

    function _getFlowrate(address sender) internal view returns(int96 flowrate) {
        (, flowrate,,) = CFAv1.getFlow(TOKEN, sender, RECEIVER);
    }
}