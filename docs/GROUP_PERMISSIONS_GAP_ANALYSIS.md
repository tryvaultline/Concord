# Concord Group Permissions Gap Analysis

This document reviews upstream Signal Group V2 permissions and documents proposed Concord extensions.

## Upstream Signal Group V2 Permissions Matrix

Signal Groups use Signal Group V2 protocol backed by client-side encrypted credentials and ZK-proof membership checks.

| Feature / Action | Signal Group V2 Default | Concord Implementation | Notes / Gap Status |
|---|---|---|---|
| Group Ownership | Creator has Owner role | **Preserved** | Single/multi-owner support. |
| Admin Role | Granted by Owners | **Preserved** | Admins can invite and manage members. |
| Member Role | Standard participant | **Preserved** | Standard message & media privileges. |
| Edit Group Info | Admins Only or All Members | **Configurable** | Controlled via Group Master Key attribute. |
| Send Messages | All Members or Admins Only | **Configurable** | Announcement channel mode support. |
| Add Members | Admins Only or All Members | **Configurable** | Admin approval mode supported. |
| Remove Members | Admins Only | **Preserved** | Admins/Owners can evict participants. |
| Pin Messages | Local UI client setting | **Extended** | Sync pinned message list in Group State. |
| Delete Member Message | Sender only | **Proposed Extension** | Admin message deletion requires group admin signature extension. |
| Invite Links | Supported with Admin Approval option | **Preserved** | Invite links resolve using Concord Username lookup. |

---

## Technical Recommendations for Concord Extensions
1. Preserve Signal Group V2 encrypted state format (`GroupChange`, `GroupState`) to keep Signal Protocol security guarantees intact.
2. Implement **Announcement Mode** ("Only Admins can send messages") via existing `GroupAccessControl` flags.
3. Keep group metadata encrypted end-to-end with the Group Master Key.
