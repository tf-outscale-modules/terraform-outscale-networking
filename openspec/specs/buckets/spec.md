# buckets Specification

## Purpose
What one entry of `buckets` produces: the bucket and its secure defaults, versioning, default encryption, bucket policy, CORS rules and lifecycle rules, plus the plan-time warnings for public exposure.

## Requirements

### Requirement: Bucket
Each entry SHALL create one OOS bucket named after its key. `acl` SHALL default to `null` (the server default, private), accept `private`, `public-read` or `authenticated-read`, and `force_delete` SHALL default to `false`.

#### Scenario: Defaults
- **WHEN** an entry sets nothing
- **THEN** the bucket is planned with the key as its name, no ACL argument sent and `force_delete = false`

#### Scenario: Rejected ACL
- **WHEN** `acl = "public-read-write"` or `acl = "open"`
- **THEN** the plan fails with "acl must be one of private, public-read, authenticated-read."

#### Scenario: Destroy gated
- **WHEN** an entry keeps `force_delete = false` and the bucket still holds objects at destroy
- **THEN** the destroy fails instead of deleting the objects

#### Scenario: Explicit force delete
- **WHEN** `force_delete = true` is set
- **THEN** the plan shows the argument so reviewers see that destroy will purge all objects, versions and delete markers

### Requirement: Versioning
Versioning SHALL be on by default: `versioning_status` defaults to `Enabled`, accepts `Enabled` or `Suspended`, and each entry SHALL produce one versioning configuration carrying that status.

#### Scenario: Default
- **WHEN** an entry sets nothing
- **THEN** its versioning configuration is planned with status `Enabled`

#### Scenario: Suspended
- **WHEN** `versioning_status = "Suspended"`
- **THEN** the configuration is planned with status `Suspended`

#### Scenario: Rejected status
- **WHEN** `versioning_status = "Disabled"`
- **THEN** the plan fails with "versioning_status must be one of Enabled, Suspended."

### Requirement: Default encryption
Server-side encryption SHALL be on by default: `enable_encryption` defaults to `true` and creates one encryption configuration with the `AES256` algorithm; `false` creates none and is the visible opt-out.

#### Scenario: Default
- **WHEN** an entry sets nothing
- **THEN** an encryption configuration with `AES256` is planned for the bucket

#### Scenario: Opt-out
- **WHEN** `enable_encryption = false`
- **THEN** no encryption configuration is planned for that bucket and the others keep theirs

### Requirement: Bucket policy
`policy` SHALL be an optional JSON string; when set, the module SHALL create one bucket policy for the bucket, normalised so the second plan is empty. Invalid JSON SHALL be rejected.

#### Scenario: No policy
- **WHEN** `policy` is null
- **THEN** no bucket policy resource is planned

#### Scenario: Valid policy
- **WHEN** `policy = jsonencode({ Version = "2012-10-17", Statement = [...] })`
- **THEN** a bucket policy for that bucket is planned

#### Scenario: Invalid JSON
- **WHEN** `policy = "not json"`
- **THEN** the plan fails with "policy must be a valid JSON document."

### Requirement: CORS rules
`cors_rules` SHALL be an optional list of rules with `allowed_headers`, `allowed_methods`, `allowed_origins`, optional `expose_headers` and `max_age_seconds`; a non-empty list creates one CORS configuration with one block per rule. Methods SHALL be among `GET`, `PUT`, `HEAD`, `POST`, `DELETE`.

#### Scenario: No rules
- **WHEN** `cors_rules` is empty
- **THEN** no CORS configuration is planned

#### Scenario: Two rules
- **WHEN** two rules are given
- **THEN** one CORS configuration with two rule blocks is planned

#### Scenario: Rejected method
- **WHEN** a rule has `allowed_methods = ["PATCH"]`
- **THEN** the plan fails with "allowed_methods must be among GET, PUT, HEAD, POST, DELETE."

#### Scenario: Negative max age
- **WHEN** a rule has `max_age_seconds = -1`
- **THEN** the plan fails with "max_age_seconds must be zero or greater."

### Requirement: Lifecycle rules
`lifecycle_rules` SHALL be an optional list; a non-empty list creates one lifecycle configuration with one rule per item, ordered after versioning. Each rule has a unique `id`, a `status` (`Enabled` default or `Disabled`) and an optional `prefix` and `tags` filter.

#### Scenario: Expire logs after 90 days
- **WHEN** a rule has `id = "logs"`, `prefix = "logs/"` and `expiration_days = 90`
- **THEN** the lifecycle configuration holds that enabled rule

#### Scenario: Duplicate ids
- **WHEN** two rules of one bucket share `id = "logs"`
- **THEN** the plan fails with "Lifecycle rule ids must be unique within a bucket."

#### Scenario: Rejected status
- **WHEN** a rule has `status = "Paused"`
- **THEN** the plan fails with "Lifecycle rule status must be Enabled or Disabled."

### Requirement: Lifecycle rule actions
Each lifecycle rule SHALL set at least one action among `expiration_days`, `expired_object_delete_marker`, `noncurrent_version_expiration_days` and `abort_incomplete_multipart_upload_days`. `expired_object_delete_marker` SHALL NOT be combined with `expiration_days`, and a rule using `tags` SHALL NOT set the delete marker or multipart actions.

#### Scenario: Rule without action
- **WHEN** a rule sets only `id` and `prefix`
- **THEN** the plan fails with "Each lifecycle rule needs at least one action."

#### Scenario: Delete marker with expiration days
- **WHEN** a rule sets both `expiration_days` and `expired_object_delete_marker = true`
- **THEN** the plan fails with "A lifecycle rule cannot set both expiration_days and expired_object_delete_marker; use two rules."

#### Scenario: Tag filter with unsupported action
- **WHEN** a rule sets `tags` together with `expired_object_delete_marker` or `abort_incomplete_multipart_upload_days`
- **THEN** the plan fails with "A lifecycle rule using tags cannot set expired_object_delete_marker or abort_incomplete_multipart_upload_days."

### Requirement: Public exposure warning
A `check` block SHALL warn, without failing the plan, for each bucket whose `acl` is `public-read`, whose policy contains an `Allow` statement with `Principal` `"*"`, or whose CORS rules allow the origin `"*"`; each warning names the bucket and the setting.

#### Scenario: Public read ACL
- **WHEN** `acl = "public-read"`
- **THEN** the plan succeeds and a warning names the bucket and says its objects are readable by anyone

#### Scenario: Everyone principal
- **WHEN** the policy has `Effect = "Allow"` and `Principal = "*"`
- **THEN** a warning names the bucket and the statement

#### Scenario: Wildcard CORS origin
- **WHEN** a CORS rule has `allowed_origins = ["*"]`
- **THEN** a warning names the bucket

#### Scenario: Private bucket
- **WHEN** no public setting is used
- **THEN** no warning is emitted
