#!/bin/sh
# -------------------------------------------------------------------------
#   delete tas
# -------------------------------------------------------------------------

container=$(docker ps | grep postgres |  cut -d " " -f1)
taskid=$1
sudo docker exec -it $container psql -U pacs -d pacsdb -c "delete from task where pk = $taskid;"
</html>
