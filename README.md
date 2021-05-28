# data-purge

Reference: https://www.sherbaz.com/data-purge-on-connected-tables-part-2-with-filter/

There was a requirement to delete data from a lot of tables connected with foreign keys without disabling the constrain or using CASCADE feature. Hence here is a simple technique applicable for smaller tables. For large tables, data has to be purged in batches. I am still working on that part at the moment. I used AdventureWorks sample database for this project.

Note: If you are in a hurry to copy-paste and execute the script, scroll down to the bottom of this post and copy the final script. All other scripts above are only sections of the code to help you understand the functioning of the final script and explains how I built the final script.
