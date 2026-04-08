# Launch Checklist

This checklist is tailored to the current Rails app structure and feature set:

- folders and nested folders
- file upload and folder upload
- bulk actions: share, download, move, delete
- public share links
- authentication and user-owned content

Use this as the final pre-launch review before going live.

## Must Fix Before Launch

### Security and Access Control

- Verify every folder, file, bulk action, and share-link controller action is user-scoped.
- Confirm users cannot access another user's folders/files by changing IDs in the URL.
- Confirm bulk actions only affect items visible inside the current scoped folder view.
- Verify share links only expose intended folders/files and nothing outside the shared scope.
- Test password-protected, disabled, expired, and login-required share-link flows if enabled.
- Review file upload handling for dangerous filenames and oversized uploads.
- Confirm CSRF protection works on standard forms and JavaScript-posted actions.

### Core Functionality

- Test creating, renaming, opening, moving, downloading, and deleting folders.
- Test uploading a single file, multiple files, and a folder with nested subfolders.
- Confirm folder upload preserves the nested structure correctly.
- Test file preview and direct download.
- Test bulk share, bulk download, bulk move, and bulk delete.
- Test single-item share and move from kebab menus.
- Test breadcrumbs and back navigation for nested folders.
- Test share-link creation for both folders and direct files.
- Test public share pages for preview and download behavior.

### Data Integrity

- Test moving a folder into itself or into one of its descendants and confirm it is blocked.
- Test deleting folders that contain nested folders and files.
- Test deleting shared folders/files and confirm old share references are cleaned correctly.
- Test duplicate names for folders and files and confirm behavior is acceptable.
- Test long names and special characters in folder/file names.
- Test empty states and invalid submissions such as bulk actions with nothing selected.

### Production Readiness

- Confirm production database migrations run cleanly.
- Confirm assets compile and page JavaScript loads correctly in production.
- Confirm file storage works in production for upload, preview, and download.
- Verify environment variables, secret keys, host settings, and storage credentials.
- Confirm HTTPS is enabled and correct host/domain settings are in place.
- Set up error tracking before launch.
- Set up database and file-storage backup strategy.

## Should Improve Before Launch

### Codebase Cleanup

- Move remaining inline `style=""` attributes in ERB files into CSS classes.
- Continue separating view markup from page-specific JavaScript and CSS.
- Extract repeated modal and toolbar markup into partials.
- Standardize naming of IDs, classes, and data attributes across pages.
- Remove dead CSS, old JavaScript, and any unused routes or actions.
- Review controllers and reduce duplicated logic where possible.

### Automated Testing

- Add request specs for folders, files, and share-link controller flows.
- Add system/browser tests for upload, bulk actions, and public sharing.
- Add tests for access control and unauthorized cross-user access attempts.
- Add tests for edge cases: empty selections, invalid target folders, expired share links.

### UI and UX Quality

- Review spacing, alignment, button sizing, and consistency across dashboard and folder pages.
- Make sure all destructive actions use clear confirmation prompts.
- Improve empty states for folders, files, search results, and share pages.
- Confirm responsive layout works on tablet and mobile widths.
- Review wording and grammar across the app for a more professional tone.
- Remove any debug leftovers such as `console.log` and temporary comments.

### Performance

- Check for N+1 queries on folders, files, and share links.
- Verify large folder lists still load and search smoothly.
- Test large zip downloads and confirm acceptable speed/memory behavior.
- Preload attachments and associated records where needed.

## Nice To Have After Launch

### Product Polish

- Add a branded favicon and consistent page titles.
- Improve visual polish for modals, toolbars, empty states, and flash messages.
- Add clearer upload progress or loading feedback.
- Add file icons by type and richer metadata display.
- Improve search and sorting UX if lists become large.

### Admin and Monitoring

- Add admin visibility into uploads, share-link activity, and errors.
- Add analytics for feature usage if needed.
- Add audit-style logging for destructive bulk actions.

### Feature Enhancements

- Add pagination or lazy loading for large folders.
- Add drag-and-drop move support.
- Add rename for files if needed.
- Add expiring share links, password options, and access toggles in a more discoverable UI.

## Manual QA Pass

Run this full manual pass before production release:

1. Sign up, log in, and log out.
2. Create top-level folders and nested folders.
3. Upload files and upload a full folder structure.
4. Select rows and verify bulk toolbar behavior.
5. Test bulk share, download, move, and delete.
6. Open share links in a private/incognito window.
7. Verify public preview/download permissions.
8. Test all empty states and validation errors.
9. Test on desktop and mobile viewport.
10. Repeat key flows with a second user account to confirm ownership isolation.

## Launch Gate

Do not publish live until all of these are true:

- No known authorization bugs.
- No broken upload, move, delete, or share flows.
- Production asset loading is confirmed.
- Storage is configured and tested.
- Backup and error monitoring are in place.
- Manual QA pass is complete.
