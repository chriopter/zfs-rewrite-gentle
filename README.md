# zfs-rewrite-gentle

After a pool expansion, old blocks stay on their original vdevs, leaving allocation uneven.

This can waste space and hurt performance until data is rewritten across the pool.  
`zfs rewrite` rewrites files without modification, applying current compression/checksum settings.

This script automates rewrites during off-hours (03:00–06:00) to keep TrueNAS usable.  
