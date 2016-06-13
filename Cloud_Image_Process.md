### Goal

Create a clear process, which outlines ownership throughout each sub-flow, with a breakdown of mid-level tasks, order of execution, timelines for delivery and standards for process management.



### Owners

- Strategic Partnerships - Relationship, direction & project
- Omnibus team - Packing and maintaining
- Partner Marketing team - Announcements and promotions

### Project Building Blocks

- Progress Tracking: GitLab issue
- Project Storage: Omnibus repository
- Documentation: Omnibus section documentation
- Partnership Details & Contacts: dedicated partnership Google Doc
- Credential Management of Cloud Services: GitLab Images 1Password vault
- Marketing Resources: need information of where logos are stored (to add to the process)

### First Time Images

- Project Owner: Strategic Partnerships

1. Introduction & Scope - initiated by Strategic Partnerships:
    1. Create issue for first time image
    2. Gathering of documentation on integrating with the Cloud Partner
    3. Understand joint marketing efforts opportunities for collaboration on launch
    4. Setup GitLab account on Cloud Partner’s system
    5. Optional: Initiate technical call with Omnibus team member and partner tech/product lead (at request of Omnibus team)
    6. Introduce Partner Marketing to marketing contacts from Cloud Partner

2. Technical Implementation - led by Omnibus team:
    1. Scope level of effort
    2. Update issue with Assignee and Due Date
    3. Upload image to cloud service - see it through partner testing:
        1. Follow-up with Cloud Partner’s support team, if needed
        2. If Cloud Partner’s support team is unresponsive, escalate to Strategic Partnerships

    4. Create new section in documentation - align MR with marketing launch

3. Marketing - led by Partner Marketing:
    1. Create marketing issue
    2. Align on joint marketing activities with partner marketing from Cloud Partner:
        1. Joint blog posts (on GitLab and Cloud Partner blogs)
        2. Social network burst

    3. Write image description that will be part of the image on the cloud service (seek assistance from technical writer if necessary)
    4. Align release to market with Product Lead from Cloud Partner
    5. Customer story/quote - locate an existing GitLab customer who would use this feature for a marketing quote or story

Process flow: step 1 must be complete before step 2 & 3 begin. Steps 2 & 3 can start and progress simultaneously.

### Maintaining Existing Images

If an omnibus package has been uploaded - maintenance won’t be necessary for version or security updates.

- Image update/maintenance catalysts:
    - New release
        - Timeline: an image update should be released within 3 business days following the release

    - Security vulnerability update

- Implementation - led by Omnibus team:
    - Create new issue
    - Update image
    - Update documentation

- Technical Info - led by marketing:
    - Update image description and documentation on cloud partner platform
