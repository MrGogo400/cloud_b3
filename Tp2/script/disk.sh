#!/bin/bash
#set -xv

if [[ $HOSTNAME == "node3" ]]; then
    echo "Partionnement du Disque Numéro 1"
    fdisk /dev/vdb << EOF
    n
    p
    1
    
    
    t
    8E
    w
EOF
    echo "Partionnement du Disque Numéro 2"
    fdisk /dev/vdc << EOF
    n
    p
    1
    
    
    t
    8E
    w
EOF
    mkdir /minio /minio-2
    pvcreate /dev/vdb1
    pvcreate /dev/vdc1
    vgcreate node3-1 /dev/vdb1
    vgcreate node3-2 /dev/vdc1
    lvcreate -l 100%FREE node3-1 -n data
    lvcreate -l 100%FREE node3-2 -n data2
    mount /dev/node3-1/data /minio
    echo -e "$(blkid |grep $HOSTNAME--1 |awk -F" " '{print $2}'|tr -d '"') /minio\t\text4\tdefaults\t0 0" >> /etc/fstab
    mount /dev/node3-2/data2 /minio-2
    echo -e "$(blkid |grep $HOSTNAME--2 |awk -F" " '{print $2}'|tr -d '"') /minio-2\t\text4\tdefaults\t0 0" >> /etc/fstab

else
    echo "Partionnement du Disque"
    fdisk /dev/vdb << EOF
    n
    p
    1
    
    
    t
    8E
    w
EOF
    mkdir /minio
    pvcreate /dev/vdb1
    vgcreate ${HOSTNAME} /dev/vdb1
    lvcreate -l 100%FREE ${HOSTNAME} -n data
    mount /dev/${HOSTNAME}/data /minio
    echo -e "$(blkid |grep $HOSTNAME |awk -F" " '{print $2}'|tr -d '"') /minio\t\text4\tdefaults\t0 0" >> /etc/fstab
fi

echo "Fin du partitionnement"
