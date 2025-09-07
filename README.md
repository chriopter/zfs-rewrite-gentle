# zfs-rewrite-gentle

After RAIDZ vdev expansion, existing blocks keep their old layout and don’t benefit from the new stripe width.  
This reduces space efficiency until blocks are rewritten with the wider geometry.  

`zfs rewrite` refreshes files in place, applying the current record/parity layout and dataset properties.  

This script automates rewrites during configured off-hours (03:00–06:00) to avoid making TrueNAS unusable.  
