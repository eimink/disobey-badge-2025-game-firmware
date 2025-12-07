# This is the file that is run when device starts

# import frozen_fs mounts `frozen_fs` as `/readonly_fs`
import frozen_fs
from bdg.config import Config
from bdg.version import Version
from ota import rollback as ota_rollback
from ota import status as ota_status


print(f"Booting..")
print("Disobey 2026")
print(f"Version: {Version().version}")
print(f"Build: {Version().build}")
print(f"")
print(f"Global variables and objects available:")
print(f"  - 'config': Config() object with firmware version info")
print(f"")
print(f"Check also Badge API documentation in Github")

# Acknowledge OTA was successful and rollback is not needed as we've booted successfully
boot_partition = ota_status.boot_ota()
if not boot_partition.info()[4] == "factory":
    # Do rollback only when we are not booting from factory partition
    ota_rollback.cancel()

Config.load()
globals()["config"] = Config()
