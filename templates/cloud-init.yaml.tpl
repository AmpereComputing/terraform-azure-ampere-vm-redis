#cloud-config

package_update: true
package_upgrade: true

packages:
  - screen
  - rsync
  - git
  - curl
  - wget
  - python3-pip
  - git-email
  - git-doc

runcmd:
  - echo 'OCI Ampere A1 Redis.' >> /etc/motd
