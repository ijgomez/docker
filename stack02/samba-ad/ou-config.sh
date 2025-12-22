#!/bin/bash
# Configuración de la jerarquía de Unidades Organizativas (OUs) para Active Directory
# Este archivo define las rutas DN (Distinguished Names) y relativas de las OUs
# que se utilizarán en create-groups.sh

# DN completos para creación de OUs
OU_GROUPS_DN="OU=Groups,$DOMAIN_DN"
OU_SECURITY_DN="OU=Security,OU=Groups,$DOMAIN_DN"
OU_APPLICATIONS_DN="OU=Applications,OU=Security,OU=Groups,$DOMAIN_DN"

# Rutas relativas (sin DC=...) para creación de grupos con --groupou
OU_APPLICATIONS_REL="OU=Applications,OU=Security,OU=Groups"

# Sub-OU bajo Applications y grupos específicos
SUB_OU_NAME=${APP_SUB_OU_NAME:-Stack02}
OU_STACK02_DN="OU=${SUB_OU_NAME},${OU_APPLICATIONS_DN}"
OU_STACK02_REL="OU=${SUB_OU_NAME},${OU_APPLICATIONS_REL}"
