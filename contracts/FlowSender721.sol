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

contract FlowSender721Factory {

    event Deployed(FlowSender721 deployedAt, ISuperToken indexed superToken, address indexed receiver);

    IConstantFlowAgreementV1 immutable cfa;

    constructor(ISuperfluid host) {
        cfa = IConstantFlowAgreementV1(address(host.getAgreementClass(keccak256(
            "org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
        ))));
    }

    /**
     * Deploys an instance of FlowSender721 with the given parameters.
     * Reverts if such an instance already exists.
     * Use `getAddressFor` with the same arguments in order to determine if already deployed.
     */
    function deployFor(ISuperToken superToken, address receiver)
        external returns(FlowSender721 deployedAt)
    {
        // deploy with CREATE2 in order to avoid duplicates
        deployedAt = new FlowSender721{salt:0x0}(
            cfa,
            superToken,
            receiver
        );
        emit Deployed(deployedAt, superToken, receiver);
    }


    function getAddressFor(ISuperToken superToken, address receiver)
        external view returns(address instanceAddr, bool isDeployed)
    {
        instanceAddr = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            bytes32(0x0), // salt
            keccak256(
                abi.encodePacked(
                    type(FlowSender721).creationCode,
                    abi.encode(cfa, superToken, receiver)
                )
        ))))));

        uint256 codeSize;
        // solhint-disable-next-line no-inline-assembly
        assembly { codeSize := extcodesize(instanceAddr) }
        isDeployed = codeSize > 0 ? true : false;
    }
}