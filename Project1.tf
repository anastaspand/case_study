# Configure the Microsoft Azure Provider
provider "azurerm" {
}

# Create a resource group
resource "azurerm_resource_group" "Project1" {
    name     = var.resource_group_name
    location = var.location

    tags = {
        environment = var.environment
    }
}


# Create virtual network
resource "azurerm_virtual_network" "Project1-network" {
    name                = "myVnet"
    address_space       = [var.vnet_cidr]
    location            = var.location
    resource_group_name = azurerm_resource_group.Project1.name

    tags = {
        environment = var.environment
    }
}

# Create subnet
resource "azurerm_subnet" "Project1-subnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.Project1.name
    virtual_network_name = azurerm_virtual_network.Project1-network.name
    address_prefix       = var.subnet_cidr
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "Project1-NSG" {
    name                = "myNetworkSecurityGroup"
    location            = var.location
    resource_group_name = azurerm_resource_group.Project1.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "Jenkins"
        priority                   = 1011
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "30000"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = var.environment
    }
}

# Create public IPs
resource "azurerm_public_ip" "masterkube-pubIP" {
    name                         = "masterkube-pubIP"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.Project1.name
    allocation_method            = "Static"

    tags = {
        environment = var.environment
    }
}


resource "azurerm_public_ip" "Node1-pubIP" {
    name                         = "Node1-pubIP"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.Project1.name
    allocation_method            = "Static"

    tags = {
        environment = var.environment
    }
}

resource "azurerm_public_ip" "Node2-pubIP" {
    name                         = "Node2-pubIP"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.Project1.name
    allocation_method            = "Static"

    tags = {
        environment = var.environment
    }
}


# Public IP for Jenkins Load Balancer
resource "azurerm_public_ip" "Jenkins-PublicIP" {
    name                         = "Jenkins-PublicIP"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.Project1.name
    allocation_method            = "Static"
    domain_name_label   = var.jenkins_dnslabel
  
   tags = {
        environment = var.environment
    }
}

# Configuration Load Balancer for Jenkins
resource "azurerm_lb" "Jenkins-LB" {
  name                = "Jenkins-LB"
  location            = var.location
  resource_group_name = azurerm_resource_group.Project1.name
  frontend_ip_configuration {
    name                 = "Jenkins-PublicIP"
    public_ip_address_id = azurerm_public_ip.Jenkins-PublicIP.id
  }
   tags = {
        environment = var.environment
    }
}
resource "azurerm_lb_backend_address_pool" "backendpool" {
  resource_group_name = azurerm_resource_group.Project1.name
  loadbalancer_id     = azurerm_lb.Jenkins-LB.id
  name                = "BackEndAddressPool"
}
resource "azurerm_lb_probe" "health_probe" {
  resource_group_name = azurerm_resource_group.Project1.name
  loadbalancer_id     = azurerm_lb.Jenkins-LB.id
  name                = "health_probe"
  protocol            = "tcp"
  port                = 30000
  interval_in_seconds = 5
  number_of_probes    = 2
}
resource "azurerm_lb_rule" "lb_rule" {
  resource_group_name            = azurerm_resource_group.Project1.name
  loadbalancer_id                = azurerm_lb.Jenkins-LB.id
  name                           = "LBRule"
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 30000
  frontend_ip_configuration_name = "Jenkins-PublicIP"
  enable_floating_ip             = false
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backendpool.id
  idle_timeout_in_minutes        = 5
  probe_id                       = azurerm_lb_probe.health_probe.id
  depends_on                     = [azurerm_lb_probe.health_probe]
}


# Create network interface for each VM
resource "azurerm_network_interface" "masterkube-nic" {
    name                      = "masterkube-nic"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.Project1.name
    network_security_group_id = azurerm_network_security_group.Project1-NSG.id

    ip_configuration {
        name                          = "masterkube-nicConfiguration"
        subnet_id                     = azurerm_subnet.Project1-subnet.id
        private_ip_address_allocation = "Static"
		private_ip_address = "10.10.1.10"
		load_balancer_backend_address_pools_ids = [azurerm_lb_backend_address_pool.backendpool.id]
        public_ip_address_id          = azurerm_public_ip.masterkube-pubIP.id
    }

    tags = {
        environment = var.environment
    }
}
resource "azurerm_network_interface" "node1-nic" {
    name                      = "node1-nic"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.Project1.name
    network_security_group_id = azurerm_network_security_group.Project1-NSG.id

    ip_configuration {
        name                          = "node1-nicConfiguration"
        subnet_id                     = azurerm_subnet.Project1-subnet.id
        private_ip_address_allocation = "Static"
		private_ip_address = "10.10.1.11"
		load_balancer_backend_address_pools_ids = [azurerm_lb_backend_address_pool.backendpool.id]
        public_ip_address_id          = azurerm_public_ip.Node1-pubIP.id
    }

    tags = {
        environment = var.environment
    }
}

resource "azurerm_network_interface" "node2-nic" {
    name                      = "node2-nic"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.Project1.name
    network_security_group_id = azurerm_network_security_group.Project1-NSG.id

    ip_configuration {
        name                          = "node1-nicConfiguration"
        subnet_id                     = azurerm_subnet.Project1-subnet.id
        private_ip_address_allocation = "Static"
		private_ip_address = "10.10.1.12"
		load_balancer_backend_address_pools_ids = [azurerm_lb_backend_address_pool.backendpool.id]
        public_ip_address_id          = azurerm_public_ip.Node2-pubIP.id
    }

    tags = {
        environment = var.environment
    }
}


# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.Project1.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "Project1-StorageAcc" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.Project1.name
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = var.environment
    }
}

# Create availability set for VMs
resource "azurerm_availability_set" "avset" {
	name                         = "avset"
	location                     = var.location
	resource_group_name          = azurerm_resource_group.Project1.name
	platform_fault_domain_count  = 3
	platform_update_domain_count = 3
	managed                      = true
}

# Create 3 virtual machines

resource "azurerm_virtual_machine" "MasterKube" {
    name                  = "MasterKube"
    location              = var.location
    resource_group_name   = azurerm_resource_group.Project1.name
    network_interface_ids = [azurerm_network_interface.masterkube-nic.id]
    vm_size               = "Standard_B2s"
	availability_set_id   = azurerm_availability_set.avset.id
	
    storage_os_disk {
        name              = "MasterKubeOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "OpenLogic"
        offer     = "CentOS"
        sku       = "7.5"
        version   = "latest"
    }

    os_profile {
        computer_name  = "MasterKube"
        admin_username = var.vm_username
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/albi/.ssh/authorized_keys"
            key_data = var.ssh_key
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = azurerm_storage_account.Project1-StorageAcc.primary_blob_endpoint
    }

    tags = {
        environment = var.environment
    }
}


resource "azurerm_virtual_machine" "Node1" {
    name                  = "NODE1"
    location              = var.location
    resource_group_name   = azurerm_resource_group.Project1.name
    network_interface_ids = [azurerm_network_interface.node1-nic.id]
    vm_size               = "Standard_B2s"
	availability_set_id   = azurerm_availability_set.avset.id
	
    storage_os_disk {
        name              = "Node1OsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "OpenLogic"
        offer     = "CentOS"
        sku       = "7.5"
        version   = "latest"
    }

    os_profile {
        computer_name  = "NODE1"
        admin_username = var.vm_username
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/albi/.ssh/authorized_keys"
            key_data = var.ssh_key
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = azurerm_storage_account.Project1-StorageAcc.primary_blob_endpoint
    }

    tags = {
        environment = var.environment
    }
}




resource "azurerm_virtual_machine" "Node2" {
    name                  = "NODE2"
    location              = var.location
    resource_group_name   = azurerm_resource_group.Project1.name
    network_interface_ids = [azurerm_network_interface.node2-nic.id]
    vm_size               = "Standard_B2s"
	availability_set_id   = azurerm_availability_set.avset.id
	
    storage_os_disk {
        name              = "Node2OsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "OpenLogic"
        offer     = "CentOS"
        sku       = "7.5"
        version   = "latest"
    }

    os_profile {
        computer_name  = "NODE2"
        admin_username = var.vm_username
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/albi/.ssh/authorized_keys"
            key_data = var.ssh_key
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = azurerm_storage_account.Project1-StorageAcc.primary_blob_endpoint
    }

    tags = {
        environment = var.environment
    }
}

output "Jenkins-FQDN" {
  value = azurerm_public_ip.Jenkins-PublicIP.fqdn
}

output "MasterKube-IP" {
  value = azurerm_public_ip.masterkube-pubIP.ip_address
}

output "Node1-IP" {
  value = azurerm_public_ip.Node1-pubIP.ip_address
}

output "Node2-IP" {
  value = azurerm_public_ip.Node2-pubIP.ip_address
}


