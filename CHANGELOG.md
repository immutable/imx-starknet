# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.1.0] - 2022-05-26

Initial release!

## [0.1.1] - 2022-05-27

### Added

- Changelog

### Changed

- Minor ts config change
- Changed folder structure for test utils

### Fixed

- Minor README/documentation fixes
- Added `cairolib` as an install dependency

## [0.2.0] - 2022-06-16

### Added

- NFT bridging protocol (Arch)

### Changed

- Upgrade to support StarkNet 0.9.0

### Fixed

- Minor README/documentation changes

# [0.2.1] - 2022-07-11

### Added

- Protostar tests
- Added `name()` and `symbol()` to `IERC721` for testing

### Changed

- Upgrade to support OpenZeppelin 0.2.1
- Removed AccessControl implementation, chenged to using OpenZeppelin implementation instead
- `IERC2981_Unidirectional_Royalties` is now `IERC721_Unidirectional`

### Fixed

- `PaymentSplitter` now starts index from 0 instead of 1
- `ERC721_Token_Metadata` now returns empty felt array when both base and token uri are undefined
