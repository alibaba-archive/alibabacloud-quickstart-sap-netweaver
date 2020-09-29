English | [简体中文](README-CN.md)

<h1 align="center">alibabacloud-quickstart-sap-netweaver</h1>

## Purpose

SAP automated tool “sap-netweaver” create and configure basic cloud resources, NetWeaver applications and HANA database, HSR(HANA System Replication), high-availability cluster, optional RDP system and audit services in the same availability zone.


sap-netweaver supports the following templates:

+ SAP NetWeaver single node template(new VPC, existing VPC)
+ SAP NetWeaver high availability template(new VPC, existing VPC)

sap-netweaver supports the following NetWeaver versions:
+ NetWeaver 7.4SR2
+ NetWeaver 7.5

View deployment guide please refer to the official website of Alibaba Cloud[《SAP 自动化安装部署最佳实践》](https://www.aliyun.com/acts/best-practice/preview)

## Directory Structure

```yaml
├──  sap-netweaver-single-node # NetWeaver single node
    ├── scripts # Scripts directory
    │   ├── sap_netweaver_single_node.sh # NetWeaver single node installation
    │   ├── sap_netweaver_single_node_input_parameter.cfg # NetWeaver parameter file
    ├── templates # ROS template directory
    │   ├── NetWeaver_Single_Node.json  # NetWeaver single node basic template:Create ECS,security groups,RAM,etc cloud resources
    │   ├── New_VPC_NetWeaver_Single_Node.json # NetWeaver single node new VPC template
    │   ├── New_VPC_NetWeaver_Single_Node_In.json # NetWeaver single node new VPC template(English version)
    │   ├── Existing_VPC_NetWeaver_Single_Node.json # NetWeaver single node existing VPC template
    │   ├── Existing_VPC_NetWeaver_Single_Node_In.json # NetWeaver single node existing VPC template(English version)

├──  sap-netweaver-ha  # NetWeaver HA cluster
    ├── scripts # Scripts directory
    │   ├── sap_netweaver_ha_node.sh # NetWeaver HA installation script
    │   ├── corosync_configuration_template.cfg # Corosync configuration file
    │   ├── sap_netweaver_ha_configuration_template.cfg # cluster resource configuration file
    │   ├── sap_netweaver_ha_input_parameter.cfg # NetWeaver HA installation parameter file
    ├── templates # ROS template directory
    │   ├── NetWeaver_HA.json  # NetWeaver HA basic template:Create ECS,security groups,ENI,RAM,etc cloud resources
    │   ├── New_VPC_NetWeaver_HA.json # NetWeaver HA new VPC template
    │   ├── New_VPC_NetWeaver_HA_In.json # NetWeaver HA new VPC template(English version)
    │   ├── Existing_VPC_NetWeaver_HA.json # NetWeaver HA existing VPC template
    │   ├── Existing_VPC_NetWeaver_HA_In.json # NetWeaver HA existing VPC template(English version)
```

## Deployment architecture

Using SAP automated tool can deploy NetWeaver high-availability cluster as below architecture in the same availability zone:

![sap-netweaver-ha](https://img.alicdn.com/tfs/TB16hbXVUH1gK0jSZSyXXXtlpXa-1643-1826.png)
