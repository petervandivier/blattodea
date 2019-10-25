# Actual Configuration

`. ./make/*` scripts should recheck objects after deployment and dump the last listed configurations to files in this directory. You can reference the documents here in the event you bork a script and need the resource id of an object you accidentally un-tagged.

More importantly, these docs are referenced by `. ./destroy/*` scripts to identify resource IDs and ARNs for teardown. 

Currently, VPC.json & Subnets.json are symlinks to their Default counterparts. v0 of this module did not have multi-region support so name suffixing was not necessary. In lieu of doing bulk refactor at his time, I'm just going to symlink sensibly and cleanup later. 

> TODO: ¿tidy external references so I can remove the symlinks?
