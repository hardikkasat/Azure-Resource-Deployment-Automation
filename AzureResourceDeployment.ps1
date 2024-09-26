# Login to Azure Account
Login-AzAccount

# Variables
$resourceGroup = "AutoDeployResourceGroup"
$location = "EastUS"
$vnetName = "AutoDeployVNet"
$subnetName = "AutoDeploySubnet"
$vmName = "AutoDeployVM"
$vmSize = "Standard_DS1_v2"
$adminUsername = "user"
$adminPassword = ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force
$tag = @{ Owner="Hardik"; Environment="Production" }

# Create Resource Group
New-AzResourceGroup -Name $resourceGroup -Location $location -Tag $tag

# Create Virtual Network and Subnet
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $location -Name $vnetName -AddressPrefix "10.0.0.0/16"
$subnet = Add-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.0.1.0/24" -VirtualNetwork $vnet
$vnet | Set-AzVirtualNetwork

# Create Public IP for VM
$publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Location $location -Name "AutoDeployPublicIP" -AllocationMethod Static

# Create Network Interface
$nic = New-AzNetworkInterface -Name "AutoDeployNIC" -ResourceGroupName $resourceGroup -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id

# Create Virtual Machine Configuration
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize |
    Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential (New-Object PSCredential($adminUsername, $adminPassword)) |
    Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2019-Datacenter" -Version "latest" |
    Add-AzVMNetworkInterface -Id $nic.Id

# Deploy the VM
New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig

# Enable Auto-Scaling based on CPU metrics
$autoscaleSetting = New-AzAutoscaleSetting -ResourceGroupName $resourceGroup -Name "AutoScaleVM" -TargetResourceId "/subscriptions/<SubscriptionId>/resourceGroups/$resourceGroup/providers/Microsoft.Compute/virtualMachines/$vmName" -MetricName "Percentage CPU" -Operator "GreaterThan" -Threshold 75 -ScaleActionDirection "Increase" -ScaleActionCooldown "PT1H" -ScaleActionValue 1

# Add Tags for Cost Management and Categorization
Set-AzResourceGroup -Name $resourceGroup -Tag @{ Department="IT"; Project="Automation" }

Write-Host "Azure Resource Deployment Completed Successfully!"
