// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISuperfluidToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { IConstantFlowAgreementHook } from "../IConstantFlowAgreementHook.sol";

// Allows invocation of the hooks
contract CFAv1Mock {
    IConstantFlowAgreementHook public hookImplementer;

    mapping(bytes32 => int96) fakeFlowRates;
    mapping(bytes32 => uint256) fakeFlowTs;

    function setHookImplementer(IConstantFlowAgreementHook hookImplementer_) external {
        hookImplementer = hookImplementer_;
    }

    function fakeCreateFlow(
        ISuperfluidToken token,
        address sender,
        address receiver,
        address flowOperator,
        int96 flowRate
    ) 
        external
    {
        fakeFlowRates[keccak256(abi.encode(token, sender, receiver))] = flowRate;
        fakeFlowTs[keccak256(abi.encode(token, sender, receiver))] = block.timestamp;

        hookImplementer.onCreate(
            token, 
            IConstantFlowAgreementHook.CFAHookParams({
                sender: sender,
                receiver: receiver,
                flowOperator: flowOperator,
                flowRate: flowRate
            })
        );
    }

    function fakeDeleteFlow(
        ISuperfluidToken token,
        address sender,
        address receiver,
        address flowOperator,
        int96 flowRate,
        int96 oldFlowRate
    ) 
        external
    {
        hookImplementer.onDelete(
            token,
            IConstantFlowAgreementHook.CFAHookParams({
                sender: sender,
                receiver: receiver,
                flowOperator: flowOperator,
                flowRate: flowRate
            }),
            oldFlowRate
        );

        fakeFlowRates[keccak256(abi.encode(token, sender, receiver))] = 0;
        fakeFlowTs[keccak256(abi.encode(token, sender, receiver))] = 0;
    }

    // only CFA method the NFT invokes
    function getFlow(
        ISuperfluidToken token,
        address sender,
        address receiver
    )
        external view virtual
        returns (
            uint256 timestamp,
            int96 flowRate,
            uint256 deposit,
            uint256 owedDeposit
        )
    {
        return (
            fakeFlowTs[keccak256(abi.encode(token, sender, receiver))],
            fakeFlowRates[keccak256(abi.encode(token, sender, receiver))],
            uint256(int256(fakeFlowRates[keccak256(abi.encode(token, sender, receiver))])) * 3600 * 4,
            uint256(0)
        );
    }
}