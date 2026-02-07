// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IProcessorAddressProvider} from "../../interfaces/IProcessorAddressProvider.sol";
import {InitializableImmutableAdminUpgradeabilityProxy} from "../../misc/upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol";
