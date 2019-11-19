# Upgrade 128T On Boot
In certain operating environments, it may not be feasible for a Network Operations Center to closely coordinate router upgrades with a remote site. This contains implementation of a mechanism for updating 128T nodes on next system boot. The intention of this mechanism is to allow for a process in which a network administrator can prepare and send the update to a remote router node, and a site administrator can asynchronously apply the update by simply rebooting.

## Requirements
The following requirements are to be met with this mechanism.
* Network administrator is able to specify that a given node should attempt upgrade on next boot.
* Network administrator is able to specify which version of software a node should attempt to upgrade to on next boot.
* Node set to upgrade will attempt to upgrade itself to the target software version _before_ starting 128T on next boot up.
* Node is not dependent on any external connectivity during the update process, and may be completely offline.
* Following the upgrade attempt, irregardless of the outcome (success or fail), 128T should be started.
* Mechanism allows for easy automation using salt.

## Operational Workflow
The intended operational workflow for this mechanism is as follows:
1. New update becomes tested and certified for deployment to remote nodes.
2. Remote nodes are targeted for update (download only) by network administrators.
3. Download process completed, all update packages are on the local repo of the node.
4. Network administrators mark the node to upgrade on next boot.
5. Node is rebooted at a convenient time by site administrator.
6. Node delays starting 128T until one automatic upgrade is attempted.
7. No matter the outcome of the upgrade attempt, 128T is started.

## Implementation Details
The implementation assumes all update packages are found in the local repo, and no network connectivity is required. It consists of placing three files on the system.

### Environment file
The environment file located at `/etc/128technology/128tupgrade_on_next_boot` is initialized with variables `UPGRADE_ON_BOOT=false` and `VERSION=""`.

`UPGRADE_ON_BOOT` serves as a flag indicating the network administrator's intent that an update should be attempted on next system boot.

`VERSION` serves to specify the version to which the upgrade should be attempted.

The following example shows an environment file on a system which is marked for upgrade on next boot, to a specific version:
```
UPGRADE_ON_BOOT=false
VERSION="4.3.1-0.release.el7"
```

### Systemd oneshot unit file
A oneshot systemd unit is defined which loads the environment file, and passes the `UPGRADE_ON_BOOT` and `VERSION` values as arguments to it's `ExecStart` script. 

The unit is defined with the `Before=128T.service` directive, to indicate that systemd should complete the execution of this unit before attempting to start 128T.

### Upgrade script
The script referenced by the ExecStart of the oneshot systemd service is simply a wrapper around the 128T installer. It checks for the following before attempting to launch installer:

* `true` is passed to the script as it's `$1` argument
* `128T` is not running
* an update is available in the local repo

If any of these conditions are not met, the script exits and 128T starts normally without an update being attempted.

If all the conditions are met, installer is launched and an upgrade is attempted.

## Management With Salt
To manage this mechanism using salt from the 128T conductor, place the `upgrade-128t-onboot.service` and `upgrade128t.sh` files in `/srv/salt/files` on conductor. Then place the `upgrade-on-boot.sls` salt state file in `/srv/salt`.

Specify that a target asset ID download a target software version:
```
$ sudo t128-salt '<target_asset_id>' cmd.run 'install128t -p "{\"download\":{\"128T-version\":\"<target_128T_version>\"}}"'
```

Apply the `upgrade-on-boot` salt state to a target asset ID, specifying the target software version.
```
$ sudo t128-salt '<target_asset_id>' state.apply upgrade-on-boot pillar='{"upgrade_on_boot":"true","version":"<target_128T_version>"}'
```
