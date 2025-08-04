# Proxmox Pool Module

This module creates and manages resource pools in Proxmox VE for organizing and managing virtual machines and containers.

## Features

- ✅ Create and manage Proxmox resource pools
- ✅ Environment-based tagging and organization
- ✅ Flexible pool configuration with comments
- ✅ Integration with VM and container modules

## Usage

### Basic Pool Setup

```hcl
module "pools" {
  source = "./modules/proxmox-pool"
  
  pools = {
    "web-tier" = {
      pool_id = "web-tier"
      comment = "Web server resource pool"
    }
    "database-tier" = {
      pool_id = "database-tier"
      comment = "Database server resource pool"
    }
  }
  
  environment = "production"
}
```

### Multi-Environment Pool Configuration

```hcl
module "pools" {
  source = "./modules/proxmox-pool"
  
  pools = {
    "dev-web" = {
      pool_id = "dev-web"
      comment = "Development web servers"
    }
    "dev-db" = {
      pool_id = "dev-db"
      comment = "Development databases"
    }
    "staging-web" = {
      pool_id = "staging-web"
      comment = "Staging web servers"
    }
    "prod-web" = {
      pool_id = "prod-web"
      comment = "Production web servers"
    }
  }
  
  environment = "mixed"
}
```

### Using Pools with VMs

```hcl
module "pools" {
  source = "./modules/proxmox-pool"
  
  pools = {
    "application-tier" = {
      pool_id = "application-tier"
      comment = "Application servers pool"
    }
  }
  
  environment = var.environment
}

module "vms" {
  source = "./modules/proxmox-vm"
  
  vms = {
    "app-server-1" = {
      vm_id   = 201
      name    = "app-server-1"
      pool_id = "application-tier"  # Reference the pool
      # ... other VM configuration
    }
  }
  
  depends_on = [module.pools]
}
```

## Input Variables

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `pools` | Map of resource pools to create | `map(object)` | ✅ | `{}` |
| `environment` | Environment name for resource tagging | `string` | ✅ | - |

### Pool Object Schema

```hcl
{
  pool_id = string           # Unique pool identifier
  comment = optional(string) # Pool description/comment
}
```

## Outputs

| Name | Description |
|------|-------------|
| `pool_details` | Complete pool configuration details |
| `pool_ids` | List of created pool IDs |

## Pool Naming Conventions

### Recommended Naming Patterns

- **By Tier**: `web-tier`, `app-tier`, `db-tier`
- **By Environment**: `dev-web`, `staging-app`, `prod-db`
- **By Function**: `frontend`, `backend`, `monitoring`
- **By Team**: `team-alpha`, `team-beta`, `shared-services`

### Environment Prefixes

```hcl
pools = {
  "${var.environment}-web" = {
    pool_id = "${var.environment}-web"
    comment = "${title(var.environment)} web servers"
  }
  "${var.environment}-db" = {
    pool_id = "${var.environment}-db"
    comment = "${title(var.environment)} databases"
  }
}
```

## Integration with Other Modules

### VM Module Integration

```hcl
# Create pools first
module "pools" {
  source = "./modules/proxmox-pool"
  pools  = var.pools
  environment = var.environment
}

# Then create VMs referencing pools
module "vms" {
  source = "./modules/proxmox-vm"
  
  vms = {
    for k, v in var.vms : k => merge(v, {
      pool_id = v.pool_id # Pool must exist
    })
  }
  
  depends_on = [module.pools]
}
```

### Container Module Integration

```hcl
module "containers" {
  source = "./modules/proxmox-container"
  
  containers = {
    for k, v in var.containers : k => merge(v, {
      pool_id = v.pool_id
    })
  }
  
  depends_on = [module.pools]
}
```

## Pool Management Best Practices

### Organization Strategies

1. **By Environment**

   ```hcl
   pools = {
     "development" = { pool_id = "development", comment = "Dev environment" }
     "staging"     = { pool_id = "staging", comment = "Staging environment" }
     "production"  = { pool_id = "production", comment = "Prod environment" }
   }
   ```

2. **By Application Stack**

   ```hcl
   pools = {
     "frontend"  = { pool_id = "frontend", comment = "Frontend services" }
     "backend"   = { pool_id = "backend", comment = "Backend services" }
     "database"  = { pool_id = "database", comment = "Database services" }
     "cache"     = { pool_id = "cache", comment = "Caching services" }
   }
   ```

3. **By Team/Project**

   ```hcl
   pools = {
     "team-alpha"   = { pool_id = "team-alpha", comment = "Team Alpha resources" }
     "team-beta"    = { pool_id = "team-beta", comment = "Team Beta resources" }
     "shared"       = { pool_id = "shared", comment = "Shared infrastructure" }
   }
   ```

### Resource Allocation

- Use pools to implement resource quotas and limits
- Monitor resource usage per pool
- Implement backup strategies per pool
- Set up monitoring and alerting per pool

## Examples

### Simple Three-Tier Architecture

```hcl
module "pools" {
  source = "./modules/proxmox-pool"
  
  pools = {
    "web-tier" = {
      pool_id = "web-tier"
      comment = "Web/Load Balancer tier"
    }
    "app-tier" = {
      pool_id = "app-tier"
      comment = "Application/Business Logic tier"
    }
    "data-tier" = {
      pool_id = "data-tier"
      comment = "Database/Storage tier"
    }
  }
  
  environment = "production"
}
```

### Development vs Production Separation

```hcl
locals {
  environments = ["dev", "staging", "prod"]
  tiers        = ["web", "app", "db"]
  
  pools = {
    for combo in setproduct(local.environments, local.tiers) : 
    "${combo[0]}-${combo[1]}" => {
      pool_id = "${combo[0]}-${combo[1]}"
      comment = "${title(combo[0])} ${combo[1]} services"
    }
  }
}

module "pools" {
  source = "./modules/proxmox-pool"
  
  pools       = local.pools
  environment = "multi-env"
}
```

## Troubleshooting

### Common Issues

1. **Pool already exists**: Check for existing pools in Proxmox before creating
2. **Permission errors**: Ensure API token has pool management permissions
3. **Dependencies**: Ensure pools are created before VMs/containers reference them

### Verification Commands

```bash
# List all pools
pvesh get /pools

# Get pool details
pvesh get /pools/{poolid}

# List VMs in a pool
pvesh get /pools/{poolid} --output-format json
```

## Requirements

- Terraform >= 1.12.2
- Proxmox VE >= 7.0
- bpg/proxmox provider ~> 0.79

## Security Considerations

- Implement proper access controls per pool
- Use pools to enforce resource isolation
- Regular auditing of pool memberships
- Monitor resource usage per pool
