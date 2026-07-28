# Group Permissions Gap Analysis

The pinned Signal-iOS client contains upstream Group V2 support. Concord has not changed its encrypted group state or permission model.

| Requirement | Upstream state | Concord change status |
|---|---|---|
| Owner, administrator, member | Present upstream | No change |
| Adding/removing members and group metadata controls | Present upstream | No change |
| Sending restrictions / announcement mode | Requires verification against the pinned server and client | Not implemented |
| Pinning messages | Local UI behavior must be verified | Not implemented |
| Deleting other members' messages | Not an upstream permission extension | Not implemented |
| Per-member exceptions | Not an upstream Group V2 primitive | Not implemented |

No group-permission extension will be added until the local Signal-compatible group service passes two-account encrypted group-message tests.
