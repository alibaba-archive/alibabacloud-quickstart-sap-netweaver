[English](README.md) | 简体中文

<h1 align="center">alibabacloud-quickstart-sap-netweaver</h1>

## 用途

SAP自动化部署工具sap-netweaver，在同一可用区内创建和配置基础云资源、NetWeaver应用以及HANA数据库软件、HANA系统复制（HANA System Replication）、高可用集群以及可选的RDP系统和操作审计服务。


sap-netweaver支持如下部署模板：

+ SAP NetWeaver单节点模板（新建VPC、已有VPC）
+ SAP NetWeaver双节点高可用集群模板（新建VPC、已有VPC）

sap-netweaver支持如下NetWeaver版本：
+ NetWeaver 7.4SR2
+ NetWeaver 7.5

详细的自动化部署最佳实践请参考阿里云官网[《SAP 自动化安装部署最佳实践》](https://www.aliyun.com/acts/best-practice/preview)

## 文件目录

```yaml
├──  sap-netweaver-single-node # NetWeaver单节点
    ├── scripts # 脚本目录
    │   ├── sap_netweaver_single_node.sh # NetWeaver单节点安装脚本
    │   ├── sap_netweaver_single_node_input_parameter.cfg # NetWeaver单节点安装脚本参数文件
    ├── templates # 资源编排(ROS)模板目录
    │   ├── NetWeaver_Single_Node.json  # NetWeaver单节点基础模板：ECS、安全组、访问控制角色等云资源
    │   ├── New_VPC_NetWeaver_Single_Node.json # NetWeaver单节点新建VPC模板
    │   ├── New_VPC_NetWeaver_Single_Node_In.json # NetWeaver单节点新建VPC模板（国际站）
    │   ├── Existing_VPC_NetWeaver_Single_Node.json # NetWeaver单节点已有VPC模板
    │   ├── Existing_VPC_NetWeaver_Single_Node_In.json # NetWeaver单节点已有VPC模板（国际站）

├──  sap-netweaver-ha  # NetWeaver双节点高可用集群
    ├── scripts # 脚本目录
    │   ├── sap_netweaver_ha_node.sh # NetWeaver双节点高可用安装脚本
    │   ├── corosync_configuration_template.cfg # Corosync配置文件
    │   ├── sap_netweaver_ha_configuration_template.cfg # 集群resource配置文件
    │   ├── sap_netweaver_ha_input_parameter.cfg # NetWeaver双节点高可用安装脚本参数文件
    ├── templates # 资源编排(ROS)模板目录
    │   ├── NetWeaver_HA.json  # NetWeaver双节点高可用基础模板：ECS、安全组、弹性网卡、访问控制角色等云资源
    │   ├── New_VPC_NetWeaver_HA.json # NetWeaver双节点高可用新建VPC模板
    │   ├── New_VPC_NetWeaver_HA_In.json # NetWeaver双节点高可用新建VPC模板（国际站）
    │   ├── Existing_VPC_NetWeaver_HA.json # NetWeaver双节点高可用已有VPC模板
    │   ├── Existing_VPC_NetWeaver_HA_In.json # NetWeaver双节点高可用已有VPC模板（国际站）
```

## 部署架构

使用SAP自动化部署工具在同一可用区内实现的NetWeaver高可用集群架构图：

![sap-netweaver-ha](https://img.alicdn.com/tfs/TB16hbXVUH1gK0jSZSyXXXtlpXa-1643-1826.png)