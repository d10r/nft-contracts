// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IConstantFlowAgreementV1 } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import { ISuperfluid, ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

/*
* ERC-721 API for querying flows of specific SuperTokens to specific receivers.
* This can be useful e.g. for superToken gated communities.
* For any tuple of SuperToken, receiver to be supported, a copy of this contract needs to be deployed
* (could be a thin proxy delegating to a shared logic contract).
* With SuperToken and receiver set, the sender address can be interpreted as the tokenId.
* balanceOf returns the flowrate (0 if no flow exists).
* The contract holds no state, but does on-the-fly lookups into the CFA when queried.
*/
contract FlowSender721 {

    /// thrown by methods not available, e.g. transfer
    error NOT_AVAILABLE();

    /// thrown when looking up a superToken or flow which doesn't exist
    error NOT_EXISTS();

    // never emitted - TODO: we may add manual minting hook if useful
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    ISuperToken public superToken; // SuperToken of observed flows
    address public receiver; // receiver of observed flows

    IConstantFlowAgreementV1 immutable internal _cfaV1;

    constructor(IConstantFlowAgreementV1 cfa_, ISuperToken superToken_, address receiver_) {
        superToken = superToken_;
        receiver = receiver_;
        _cfaV1 = cfa_;
    }

    // ============= ERC721 interface =============

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        if (_getFlowRate(address(uint160(id))) == 0) revert NOT_EXISTS();
        return address(uint160(id));
    }

    // returns the flowrate of the owner ( == sender)
    function balanceOf(address owner) public view virtual returns (uint256) {
        return uint256(uint96(_getFlowRate(owner)));
    }

    // ERC165 Interface Detection
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // Interface ID for ERC165
            interfaceId == 0x80ac58cd; // Interface ID for ERC721
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

    function approve(address /*spender*/, uint256 /*id*/) public pure {
        revert NOT_AVAILABLE();
    }

    function setApprovalForAll(address /*operator*/, bool /*approved*/) public pure {
        revert NOT_AVAILABLE();
    }

    function getApproved(uint256 /*_tokenId*/) external pure returns (address) {
        revert NOT_AVAILABLE();
    }

    function isApprovedForAll(address /*_owner*/, address /*_operator*/) external pure returns (bool) {
        revert NOT_AVAILABLE();
    }

    // ============= private interface =============

    function _getFlowRate(address sender) internal view returns(int96 flowRate) {
        (,flowRate,,) = _cfaV1.getFlowByID(superToken, _getAgreementId(sender));
    }

    /// returns the superToken id representing the given flow - constructed like agreementId in CFA
    /// note that this method doesn't check if an actual flow currently exists for this params (flowrate > 0)
    function _getAgreementId(address sender) public view returns(bytes32 agreementId) {
        agreementId = keccak256(abi.encodePacked(
            superToken,
            sender,
            receiver
        ));
    }
}
