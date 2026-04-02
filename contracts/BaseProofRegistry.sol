// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BaseProofRegistry {
    struct Asset {
        bytes32 assetId;
        bytes32 canonicalHash;
        bytes32 rootAssetId;
        bytes32 parentAssetId;
        string metadataURI;
        address registrant;
        uint256 createdAt;
        bool revoked;
        bool exists;
    }

    struct License {
        bytes32 licenseId;
        bytes32 assetId;
        address licensee;
        string termsURI;
        uint256 createdAt;
    }

    address public owner;
    bool public paused;

    mapping(address => bool) public operators;
    mapping(bytes32 => Asset) public assets;
    mapping(bytes32 => bool) public canonicalHashUsed;
    mapping(bytes32 => bytes32[]) public childrenByParent;
    mapping(bytes32 => License) public licenses;
    mapping(bytes32 => bool) public issuedLicenses;
    mapping(bytes32 => address) public licenseIssuedBy;
    mapping(bytes32 => bytes32[]) public assetLicenses;
    mapping(bytes32 => bool) public assetHasExclusiveLicense;
    mapping(bytes32 => bool) public revokedLicenses;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OperatorUpdated(address indexed operator, bool allowed);
    event PauseStatusChanged(bool isPaused);
    event AssetRegistered(
        bytes32 indexed assetId,
        bytes32 indexed canonicalHash,
        bytes32 indexed rootAssetId,
        bytes32 parentAssetId,
        address registrant,
        string metadataURI
    );
    event AssetOwnershipTransferred(
        bytes32 indexed assetId,
        address indexed previousRegistrant,
        address indexed newRegistrant
    );
    event AssetURIUpdated(
        bytes32 indexed assetId,
        string previousMetadataURI,
        string newMetadataURI
    );
    event AssetRevocationSet(
        bytes32 indexed assetId,
        bool revokedStatus
    );
    event LicenseIssued(
        bytes32 indexed licenseId,
        bytes32 indexed assetId,
        address indexed licensee,
        string termsURI,
        uint256 createdAt
    );
    event LicenseRevoked(
        bytes32 indexed licenseId,
        bytes32 indexed assetId,
        address indexed revokedBy
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || operators[msg.sender], "Not admin");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Registry paused");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function setOperator(address operator, bool allowed) external onlyOwner {
        require(operator != address(0), "Zero address");
        operators[operator] = allowed;
        emit OperatorUpdated(operator, allowed);
    }

    function setPaused(bool _paused) external onlyOwner {
        require(paused != _paused, "Already set");
        paused = _paused;
        emit PauseStatusChanged(_paused);
    }

    function registerOriginal(
        bytes32 assetId,
        bytes32 canonicalHash,
        string calldata metadataURI
    ) external onlyAdmin whenNotPaused {
        require(bytes(metadataURI).length > 0, "Empty metadata URI");
        _validateOriginalRegistration(assetId, canonicalHash, metadataURI);

        assets[assetId] = Asset({
            assetId: assetId,
            canonicalHash: canonicalHash,
            rootAssetId: assetId,
            parentAssetId: bytes32(0),
            metadataURI: metadataURI,
            registrant: msg.sender,
            createdAt: block.timestamp,
            revoked: false,
            exists: true
        });

        canonicalHashUsed[canonicalHash] = true;

        emit AssetRegistered(
            assetId,
            canonicalHash,
            assetId,
            bytes32(0),
            msg.sender,
            metadataURI
        );
    }

    function registerDerivative(
        bytes32 assetId,
        bytes32 canonicalHash,
        bytes32 parentAssetId,
        string calldata metadataURI
    ) external onlyAdmin whenNotPaused {
        require(bytes(metadataURI).length > 0, "Empty metadata URI");
        bytes32 rootAssetId = _validateDerivativeRegistration(
            assetId,
            canonicalHash,
            parentAssetId,
            metadataURI
        );

        assets[assetId] = Asset({
            assetId: assetId,
            canonicalHash: canonicalHash,
            rootAssetId: rootAssetId,
            parentAssetId: parentAssetId,
            metadataURI: metadataURI,
            registrant: msg.sender,
            createdAt: block.timestamp,
            revoked: false,
            exists: true
        });

        canonicalHashUsed[canonicalHash] = true;
        childrenByParent[parentAssetId].push(assetId);

        emit AssetRegistered(
            assetId,
            canonicalHash,
            rootAssetId,
            parentAssetId,
            msg.sender,
            metadataURI
        );
    }

    function transferAssetOwnership(bytes32 assetId, address newRegistrant)
        external
        whenNotPaused
    {
        require(newRegistrant != address(0), "Zero address");

        Asset storage asset = _getActiveAsset(assetId);
        require(
            msg.sender == asset.registrant ||
                msg.sender == owner ||
                operators[msg.sender],
            "Not authorized"
        );
        require(asset.registrant != newRegistrant, "Already registrant");

        address previousRegistrant = asset.registrant;
        asset.registrant = newRegistrant;

        emit AssetOwnershipTransferred(assetId, previousRegistrant, newRegistrant);
    }

    function updateAssetURI(bytes32 assetId, string calldata newMetadataURI)
        external
        whenNotPaused
    {
        require(bytes(newMetadataURI).length > 0, "Empty metadata URI");

        Asset storage asset = _getActiveAsset(assetId);
        require(
            msg.sender == asset.registrant ||
                msg.sender == owner ||
                operators[msg.sender],
            "Not authorized"
        );
        require(
            keccak256(bytes(asset.metadataURI)) != keccak256(bytes(newMetadataURI)),
            "Metadata URI unchanged"
        );

        string memory previousMetadataURI = asset.metadataURI;
        asset.metadataURI = newMetadataURI;

        emit AssetURIUpdated(assetId, previousMetadataURI, newMetadataURI);
    }

    function setAssetRevoked(bytes32 assetId, bool revokedStatus)
        external
        onlyAdmin
        whenNotPaused
    {
        Asset storage asset = _getExistingAsset(assetId);
        require(asset.revoked != revokedStatus, "Already set");

        asset.revoked = revokedStatus;

        emit AssetRevocationSet(assetId, revokedStatus);
    }

    function issueLicense(
        bytes32 licenseId,
        bytes32 assetId,
        address licensee,
        string calldata termsURI
    ) external onlyAdmin whenNotPaused {
        Asset storage asset = _validateLicenseCreation(
            licenseId,
            assetId,
            licensee,
            termsURI
        );

        require(!asset.revoked, "Asset is revoked");

        bool isExclusive = keccak256(bytes(termsURI)) == keccak256(bytes("exclusive"));
        if (isExclusive) {
            require(!assetHasExclusiveLicense[assetId], "Exclusive license already issued");
            assetHasExclusiveLicense[assetId] = true;
        }

        licenses[licenseId] = License({
            licenseId: licenseId,
            assetId: assetId,
            licensee: licensee,
            termsURI: termsURI,
            createdAt: block.timestamp
        });

        issuedLicenses[licenseId] = true;
        licenseIssuedBy[licenseId] = msg.sender;
        assetLicenses[assetId].push(licenseId);

        emit LicenseIssued(
            licenseId,
            assetId,
            licensee,
            termsURI,
            block.timestamp
        );
    }

    function revokeLicense(bytes32 licenseId) external whenNotPaused {
        require(licenseId != bytes32(0), "Invalid licenseId");
        require(issuedLicenses[licenseId], "License does not exist");
        require(!revokedLicenses[licenseId], "License already revoked");
        require(
            msg.sender == owner ||
                operators[msg.sender] ||
                msg.sender == licenseIssuedBy[licenseId],
            "Not authorized"
        );

        revokedLicenses[licenseId] = true;

        emit LicenseRevoked(
            licenseId,
            licenses[licenseId].assetId,
            msg.sender
        );
    }

    function verifyHash(bytes32 assetId, bytes32 contentHash) external view returns (bool) {
        if (!assets[assetId].exists) {
            return false;
        }

        return assets[assetId].canonicalHash == contentHash;
    }

    function getAsset(bytes32 assetId)
        external
        view
        returns (
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            string memory,
            address,
            uint256,
            bool,
            bool
        )
    {
        Asset memory asset = _getExistingAsset(assetId);

        return (
            asset.assetId,
            asset.canonicalHash,
            asset.rootAssetId,
            asset.parentAssetId,
            asset.metadataURI,
            asset.registrant,
            asset.createdAt,
            asset.revoked,
            asset.exists
        );
    }

    function getLicense(bytes32 licenseId)
        external
        view
        returns (
            bytes32,
            bytes32,
            address,
            string memory,
            uint256,
            bool,
            address
        )
    {
        require(issuedLicenses[licenseId], "License does not exist");

        License memory license = licenses[licenseId];

        return (
            license.licenseId,
            license.assetId,
            license.licensee,
            license.termsURI,
            license.createdAt,
            revokedLicenses[licenseId],
            licenseIssuedBy[licenseId]
        );
    }

    function getChildren(bytes32 parentAssetId) external view returns (bytes32[] memory) {
        _getExistingAsset(parentAssetId);
        return childrenByParent[parentAssetId];
    }

    function getAssetLicenses(bytes32 assetId) external view returns (bytes32[] memory) {
        _getExistingAsset(assetId);
        return assetLicenses[assetId];
    }

    function isLicenseActive(bytes32 licenseId) external view returns (bool) {
        if (!issuedLicenses[licenseId]) {
            return false;
        }

        if (revokedLicenses[licenseId]) {
            return false;
        }

        bytes32 assetId = licenses[licenseId].assetId;

        if (!assets[assetId].exists) {
            return false;
        }

        if (assets[assetId].revoked) {
            return false;
        }

        return true;
    }

    function _requireValidAssetId(bytes32 assetId) internal pure {
        require(assetId != bytes32(0), "Invalid assetId");
    }

    function _validateOriginalRegistration(
        bytes32 assetId,
        bytes32 canonicalHash,
        string calldata metadataURI
    ) internal view {
        _requireValidAssetId(assetId);
        require(canonicalHash != bytes32(0), "Invalid canonical hash");
        require(bytes(metadataURI).length > 0, "Empty metadata URI");
        require(!assets[assetId].exists, "Asset already exists");
        require(!canonicalHashUsed[canonicalHash], "Canonical hash already used");
    }

    function _validateDerivativeRegistration(
        bytes32 assetId,
        bytes32 canonicalHash,
        bytes32 parentAssetId,
        string calldata metadataURI
    ) internal view returns (bytes32 rootAssetId) {
        _requireValidAssetId(assetId);
        _requireValidAssetId(parentAssetId);
        require(canonicalHash != bytes32(0), "Invalid canonical hash");
        require(bytes(metadataURI).length > 0, "Empty metadata URI");
        require(!assets[assetId].exists, "Asset already exists");
        require(!canonicalHashUsed[canonicalHash], "Canonical hash already used");

        Asset storage parentAsset = _getActiveAsset(parentAssetId);
        rootAssetId = parentAsset.rootAssetId;
    }

    function _validateLicenseCreation(
        bytes32 licenseId,
        bytes32 assetId,
        address licensee,
        string calldata termsURI
    ) internal view returns (Asset storage asset) {
        require(licenseId != bytes32(0), "Invalid licenseId");
        require(licensee != address(0), "Zero address");
        require(bytes(termsURI).length > 0, "Empty terms URI");
        require(!issuedLicenses[licenseId], "License already exists");

        asset = _getExistingAsset(assetId);
        require(block.timestamp >= asset.createdAt, "Invalid license timestamp");
    }

    function _getExistingAsset(bytes32 assetId) internal view returns (Asset storage asset) {
        _requireValidAssetId(assetId);
        require(assets[assetId].exists, "Asset does not exist");
        asset = assets[assetId];
    }

    function _getActiveAsset(bytes32 assetId) internal view returns (Asset storage asset) {
        asset = _getExistingAsset(assetId);
        require(!asset.revoked, "Asset is revoked");
    }

    function isCanonicalHashUsed(bytes32 canonicalHash) external view returns (bool) {
        return canonicalHashUsed[canonicalHash];
    }

    function getAssetLineage(bytes32 assetId)
        external
        view
        returns (bytes32 rootAssetId, bytes32 parentAssetId)
    {
        Asset memory asset = _getExistingAsset(assetId);
        return (asset.rootAssetId, asset.parentAssetId);
    }
}
