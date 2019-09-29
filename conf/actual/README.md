# Actual Configuration

`. ./make/*` scripts should recheck objects after deployment and dump the last listed configurations to files in this directory. You can reference the documents here in the event you bork a script and need the resource id of an object you accidentally un-tagged.

More importantly, these docs are referenced by `. ./destroy/*` scripts to identify resource IDs and ARNs for teardown. 
