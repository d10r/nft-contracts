// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IConstantFlowAgreementV1 } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import { ISuperfluid, ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import "./FlowSender721.sol";

contract FlowSender721Factory {

    error PERMISSION_DENIED();
    error NOT_INITIALIZED();

    event Deployed(FlowSender721 deployedAt, ISuperToken indexed superToken, address indexed receiver);

    // the initializer is allowed to set the host initially, ceases to be relevant afterwards
    address immutable internal _initializer;

    IConstantFlowAgreementV1 public cfa;

    // in order to allow deployment to a deterministic address (across chains)
    // the host isn't provided in the constructor, but in a successive initialize call.
    // This works only if setting the same initializer for all deployments.
    constructor(address initializer) {
        _initializer = initializer;
    }

    function initialize(ISuperfluid host) external {
        if (msg.sender != _initializer || address(cfa) != address(0x0)) revert PERMISSION_DENIED();
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
        if (address(cfa) == address(0x0)) revert NOT_INITIALIZED();
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