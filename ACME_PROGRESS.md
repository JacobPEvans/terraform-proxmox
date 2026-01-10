# ACME Certificate Implementation Progress

**Updated:** 2026-01-07
**Branch:** feat/acme-certificate
**PR:** #65 (Draft)

## Completed ✅

### 1. Implementation Planning
- [x] Comprehensive plan document created (`.claude/plans/quizzical-herding-fountain.md`)
- [x] Quick reference guide (`ACME_IMPLEMENTATION_PLAN.md`)
- [x] GitHub issue hierarchy created:
  - **Parent:** #61 - Configure ACME certificates and HTTPS access for Proxmox
  - **Child:** #62 - Create ACME certificate Terraform module
  - **Child:** #63 - Import existing ACME resources into Terraform state
  - **Child:** #64 - Configure Proxmox for port 443 HTTPS access
  - **Child:** #65 - Configure Doppler secrets for Route53 DNS challenges
  - **Child:** #66 - Add ACME certificate management documentation

### 2. ACME Certificate Module (Issue #62)
- [x] `modules/acme-certificate/main.tf`
  - BPG Proxmox ACME account resource
  - DNS plugin resource (Route53)
  - Certificate resource
  - Proper dependency ordering
  - Lifecycle policies for drift prevention

- [x] `modules/acme-certificate/variables.tf`
  - `acme_accounts` variable with email validation
  - `dns_plugins` variable (marked sensitive)
  - `acme_certificates` variable
  - Environment variable for tagging

- [x] `modules/acme-certificate/outputs.tf`
  - Account information export
  - DNS plugin configuration export
  - Certificate metadata export

- [x] `modules/acme-certificate/README.md`
  - Module overview and features
  - Usage examples
  - Variable documentation
  - Lifecycle and renewal procedures
  - Troubleshooting guide
  - Import procedures

### 3. Root Configuration Integration
- [x] `main.tf` - ACME module instantiation
- [x] `variables.tf` - ACME variables added
- [x] `outputs.tf` - ACME outputs added

## In Progress 🚧

### 4. Doppler Secret Configuration (Issue #65)
**Status:** Awaiting user setup of Route53 IAM credentials

**Required Actions:**
1. Create AWS IAM user with Route53 least-privilege policy
2. Generate AWS access keys
3. Add secrets to Doppler:
   - `ROUTE53_ACCESS_KEY`
   - `ROUTE53_SECRET_KEY`
   - `ROUTE53_ZONE_ID`
   - `ACME_EMAIL`
   - `ACME_DOMAIN`

### 5. Resource Import (Issue #63)
**Status:** Blocked pending Doppler configuration

**Required Actions:**
1. Discover existing ACME resources via Proxmox API
2. Import ACME account into state
3. Import DNS plugin into state
4. Import certificate into state
5. Create terraform.tfvars entries matching imported state
6. Validate zero-drift with `terraform plan`

### 6. Proxmox Port 443 Configuration (Issue #64)
**Status:** Awaiting manual execution on Proxmox host

**Required Actions:**
1. Modify `/etc/default/pveproxy` on Proxmox node
2. Restart pveproxy service
3. Verify ports 443 and 8006 are listening
4. Add firewall rule for port 443 (if needed)

### 7. Documentation (Issue #66)
**Status:** Module README created; main documentation pending

**Required Actions:**
1. Create `ACME_CERTIFICATE_MANAGEMENT.md`
2. Enhance module README with deployment examples
3. Document renewal monitoring procedures
4. Create troubleshooting guide

## Next Steps

### Immediate (Required for next session)
1. **Configure Doppler secrets** - Set up Route53 IAM credentials
2. **Discover existing ACME configuration** - Query Proxmox API
3. **Import resources** - Bring existing certificates into Terraform state
4. **Test terraform plan** - Validate zero-drift after import

### Then
1. Configure Proxmox for port 443 (manual SSH to Proxmox)
2. Validate HTTPS access works on both ports
3. Complete documentation
4. Merge PR

## Testing Checklist

- [ ] `terraform init` succeeds
- [ ] `terraform validate` passes with no errors
- [ ] `terraform plan` shows expected ACME resources
- [ ] ACME account imports without modification
- [ ] DNS plugin imports without modification
- [ ] Certificate imports without modification
- [ ] Post-import `terraform plan` shows zero changes
- [ ] HTTPS works on port 443
- [ ] HTTPS still works on port 8006
- [ ] Valid certificate presented (no warnings)
- [ ] Certificate details visible in Proxmox UI

## Commits So Far

```
43b82b3 docs: Add ACME certificate implementation planning document
f5b3562 feat: Create ACME certificate Terraform module
05786ca feat: Integrate ACME certificate module into root configuration
```

## Files Modified/Created

**New Files:**
- `ACME_IMPLEMENTATION_PLAN.md` (reference guide)
- `modules/acme-certificate/main.tf` (ACME resources)
- `modules/acme-certificate/variables.tf` (module inputs)
- `modules/acme-certificate/outputs.tf` (module outputs)
- `modules/acme-certificate/README.md` (documentation)
- `ACME_PROGRESS.md` (this file)

**Modified Files:**
- `main.tf` (+11 lines - module instantiation)
- `variables.tf` (+42 lines - ACME variables)
- `outputs.tf` (+16 lines - ACME outputs)

## Key Design Decisions

✅ **Module Architecture**
- Follows existing 7-module pattern
- Uses `for_each` for multi-account/certificate support
- Conditional instantiation based on `acme_accounts`
- Proper dependency ordering and lifecycle management

✅ **Variable Structure**
- Email validation for ACME accounts
- Sensitive flag for AWS credentials
- Optional parameters with sensible defaults
- Type validation throughout

✅ **Import Strategy**
- Non-destructive import (preserves existing certificates)
- Lifecycle `ignore_changes` prevents unnecessary regeneration
- Zero-drift validation after import
- Clear import command documentation in module README

✅ **AWS Credential Management**
- All credentials in Doppler (never in tfvars)
- Least-privilege IAM policy for Route53
- Rotation strategy (90-day keys)
- Security best practices documented

## Related Work

This feature complements and enables resolution of:
- **Issue #24** - Security: Example configuration enables insecure TLS
- **Issue #42** - CRITICAL: proxmox_insecure insecure default in terraform.tfvars.example

Once ACME certificates are properly configured, `proxmox_insecure = false` can be safely enforced throughout the codebase.

## Blockers

None at module level. Proceeding with:
1. Waiting for user to configure Doppler secrets
2. Waiting for user to run discovery and import commands
3. Waiting for manual Proxmox configuration (port 443)

## Links

- **Plan Document:** `.claude/plans/quizzical-herding-fountain.md`
- **PR:** https://github.com/JacobPEvans/terraform-proxmox/pull/65
- **Parent Issue:** https://github.com/JacobPEvans/terraform-proxmox/issues/61
- **Module README:** `modules/acme-certificate/README.md`

---

**Status Summary:** ACME module complete and integrated. Ready for Doppler configuration and resource import.
