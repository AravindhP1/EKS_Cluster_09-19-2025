data "azurerm_client_config" "current" {}

# aks-cluster resource

resource "azurerm_kubernetes_cluster" "cluster" {

  # general and standard config
  name                = var.cluster_name
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.clusteer_dns_prefix
  kubernetes_version = var.kubernetes_version
  sku_tier = var.aks_sku_tier      #default or Standard, & Premium
  automatic_upgrade_channel = "node-image"    # patch, rapid, node-image and stable
  cost_analysis_enabled = false     # default or true with standard and premium sku_tier
  
  tags = var.tags
  
  identity {
    type = "SystemAssigned" #AKS creates system managed identity to manage lifecycle of other resources
  }

  # System Node Pool Config

  node_os_upgrade_channel = "NodeImage" # default
  node_resource_group = "aks-managed-rg"
  
  default_node_pool {
    name       = var.sys_node_pool_name
    vm_size    = var.vm_size
    kubelet_disk_type = "OS" # Kubelet-related data and temp storage for pod
    os_disk_type = "Managed" # default
    max_pods = var.node_pool_max_pods
    auto_scaling_enabled = var.node_pool_scaling # additional arguments below
    type = "VirtualMachineScaleSets"
    max_count = 4
    min_count = 2
    node_count = 2
    node_public_ip_enabled = false # default value
    scale_down_mode = "Delete"
    only_critical_addons_enabled = var.default_node_pool_only_critical_addons # can't schedule app pods
    os_disk_size_gb = var.node_pool_os_disk_size_gb
    os_sku = "Ubuntu"
    vnet_subnet_id = azurerm_subnet.aks_sys_subnet.id
    upgrade_settings {
      drain_timeout_in_minutes = 0
      node_soak_duration_in_minutes = 0
      max_surge = "10%"

    }

    # other argument
    # - kubelet_config -containers log max line, max processors per pod etc.
    # - fips_enabled
    # - linux_os_config - swap and fine tune kernel
  }

  run_command_enabled = true #default value - run admin tasks commands on vms
  storage_profile {
    blob_driver_enabled = true #allows to mount blob storage
    disk_driver_enabled = true  #azure attach disks
    file_driver_enabled = false #Azure file shares
    snapshot_controller_enabled = true #default
  }
  support_plan = "KubernetesOfficial" #other value - AKSLongTermSupport
  
  # additional auto scaling arguments 
  auto_scaler_profile {
    max_graceful_termination_sec = var.autoscaler_max_graceful_termination_sec  # default=600
    max_node_provisioning_time = var.autoscaler_max_node_provisioning_time # default=15m
    max_unready_nodes = var.autoscaler_max_unready_nodes # so nodes don't keep popping up
    scale_down_delay_after_add = "5m"
    skip_nodes_with_local_storage = true
    skip_nodes_with_system_pods = true  
  }

  workload_autoscaler_profile {
    vertical_pod_autoscaler_enabled = true
  }

  # pod network related
  network_profile {
    network_plugin = "azure" # cni plugin for pod networking
    # network_mode = "bridge"  # nodes act as bridge, pods get Vnet IPs
    network_policy = "azure" 
    network_plugin_mode = "overlay"
    outbound_type = "loadBalancer" #nat for pods
    pod_cidr = var.pod_cidr
    service_cidr = var.service_cidr
    dns_service_ip = var.dns_service_ip
    ip_versions = ["IPv4"]
    load_balancer_sku = "standard"
  }
  private_cluster_enabled = var.private_cluster_enabled
  role_based_access_control_enabled = true

  #security related - Azure RBAC is disabled by default
  azure_policy_enabled = var.azure_policy_enabled
  local_account_disabled = var.local_account_disabled # default value

  # aks mainteance
  maintenance_window {
    allowed {
      day = "Thursday"
      hours = [1] # 1-2AM
    }
  }
  
  # k8 mainteance
  maintenance_window_auto_upgrade {
    frequency = "RelativeMonthly"
    interval = 1
    duration = 4
    day_of_week = "Sunday"
    week_index = "Second"
    start_time = "2:00"
    utc_offset = "-07:00"
    #can't be recurring 
    not_allowed {
      start = "2025-12-24T00:00:00Z"
      end =  "2025-12-26T00:00:00Z"
    }
  }
  maintenance_window_node_os {
    frequency = "Weekly"
    interval = 1
    duration = 4
    day_of_week = "Tuesday"
    start_time = "2:00"
    utc_offset = "-07:00"
    #can't be recurring 
    not_allowed {
      start = "2025-12-24T00:00:00Z"
      end =  "2025-12-26T00:00:00Z"
    }
  }

  image_cleaner_enabled = true
  image_cleaner_interval_hours = 168 # 7 days in hours

  # other options:
  # - ingress_application_gateway
  # - key_vault_secrets_provider
  # - kubelet_identity (with user-assigned managed identity)
  # - microsoft_defender (with log analytics for defender to collect logs from)
  # - monitor_metrics (specify prometheus add-on profile)
  # - oidc_issuer_enabled
  # - oms_agent
  # - open_service_mesh_enabled
  # - service_mesh_profile
  # - workload_identity_enabled
  # - custom_ca_trust_certificates_base64
  # - azure_active_directory_role_based_access_control
  # - linux_profile
  # - windows_profile
  # - key_management_service - needs user-managed identity
}

