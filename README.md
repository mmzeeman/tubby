Tubby
=====

A process pool for running tasks.

Example

```erlang
tubby:start(my_worker_pool, {my_worker, start_link, []}),

%% Start a worker on the pool.
{ok, Pid} = tubby:run(my_worker_pool, [Arg1, Arg2]),
my_worker:do_stuff(Pid, Stuff),

%% Queue a worker on the pool. The task will run when there is room
ok = tubby:queue(my_worker_pool, [Arg1, Arg2]),

%% Or queue it, and wait for 10000 msecs until there is room.   
{ok, Pid} = tubby:queue_wait(my_worker_pool, [Arg1, Arg2], 10000),
```
