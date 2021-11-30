## 简介

现在是云原生时代。作为开发的我（们）或多说少在平常和工作中和docker或k8s打过交道。而作为JAVA开发者，我们多少会对JVM参数进行调优。  
不知道大家有没有遇到过类似情况：在容器环境下，设置-Xmx报错。  
没有也没关系，今天我们来探究下，容器环境下如何设置JAVA参数。

### 历史

* JDK8u121加入了UseCGroupMemoryLimitForHeap这一参数。(JDK-8170888)
* JDK8u191后加入了UseContainerSupport、MaxRAMPercentage、MinRAMPercentage、InitialRAMPercentage参数。

## 用法

建议使用大于8u191版本的JAVA。

### java版本<8u121

不要在容器化环境使用。

### 8u121<java版本<8u191


### java版本>=8u191



## OpenJDK相关源码解读

我对相关方法做了注释。

`osContainer_linux.cpp`
~~~
/* init
 *
 * Initialize the container support and determine if
 * we are running under cgroup control.
 *
 * 容器环境下的初始化和判定
 *
 */
void OSContainer::init() {
  int mountid;
  int parentid;
  int major;
  int minor;
  FILE *mntinfo = NULL;
  FILE *cgroup = NULL;
  char buf[MAXPATHLEN+1];
  char tmproot[MAXPATHLEN+1];
  char tmpmount[MAXPATHLEN+1];
  char tmpbase[MAXPATHLEN+1];
  char *p;
  //是否已经初始化
  assert(!_is_initialized, "Initializing OSContainer more than once");

  _is_initialized = true;
  _is_containerized = false;

  //修正_unlimited_memory
  _unlimited_memory = (LONG_MAX / os::vm_page_size()) * os::vm_page_size();

  if (PrintContainerInfo) {
    tty->print_cr("OSContainer::init: Initializing Container Support");
  }
  //UseContainerSupport没有打开则跳出去
  if (!UseContainerSupport) {
    if (PrintContainerInfo) {
      tty->print_cr("Container Support not enabled");
    }
    return;
  }

  /*
   *
   * 找到cgroup的挂在点信息
   * Find the cgroup mount point for memory and cpuset
   * by reading /proc/self/mountinfo
   *
   * Example for docker:
   * 219 214 0:29 /docker/7208cebd00fa5f2e342b1094f7bed87fa25661471a4637118e65f1c995be8a34 /sys/fs/cgroup/memory ro,nosuid,nodev,noexec,relatime - cgroup cgroup rw,memory
   *
   * Example for host:
   * 34 28 0:29 / /sys/fs/cgroup/memory rw,nosuid,nodev,noexec,relatime shared:16 - cgroup cgroup rw,memory
   */
  mntinfo = fopen("/proc/self/mountinfo", "r");
  if (mntinfo == NULL) {
      if (PrintContainerInfo) {
        tty->print_cr("Can't open /proc/self/mountinfo, %s",
                       strerror(errno));
      }
      return;
  }

  while ( (p = fgets(buf, MAXPATHLEN, mntinfo)) != NULL) {
    // Look for the filesystem type and see if it's cgroup
    char fstype[MAXPATHLEN+1];
    fstype[0] = '\0';
    char *s =  strstr(p, " - ");
    if (s != NULL &&
        sscanf(s, " - %s", fstype) == 1 &&
        strcmp(fstype, "cgroup") == 0) {

      if (strstr(p, "memory") != NULL) {
        int matched = sscanf(p, "%d %d %d:%d %s %s",
                             &mountid,
                             &parentid,
                             &major,
                             &minor,
                             tmproot,
                             tmpmount);
        if (matched == 6) {
         //内存信息
          memory = new CgroupSubsystem(tmproot, tmpmount);
        }
        else
          if (PrintContainerInfo) {
            tty->print_cr("Incompatible str containing cgroup and memory: %s", p);
          }
      } else if (strstr(p, "cpuset") != NULL) {
        int matched = sscanf(p, "%d %d %d:%d %s %s",
                             &mountid,
                             &parentid,
                             &major,
                             &minor,
                             tmproot,
                             tmpmount);
        if (matched == 6) {
          //cpuset: 用来绑定cgroup到指定CPU的哪个核上和NUMA节点
          cpuset = new CgroupSubsystem(tmproot, tmpmount);
        }
        else {
          if (PrintContainerInfo) {
            tty->print_cr("Incompatible str containing cgroup and cpuset: %s", p);
          }
        }
      } else if (strstr(p, "cpu,cpuacct") != NULL || strstr(p, "cpuacct,cpu") != NULL) {
        int matched = sscanf(p, "%d %d %d:%d %s %s",
                             &mountid,
                             &parentid,
                             &major,
                             &minor,
                             tmproot,
                             tmpmount);
        if (matched == 6) {
          //cpu：用来限制cgroup的CPU使用率
          cpu = new CgroupSubsystem(tmproot, tmpmount);
          //cpuacct: 用来统计cgroup的CPU的使用率
          cpuacct = new CgroupSubsystem(tmproot, tmpmount);
        }
        else {
          if (PrintContainerInfo) {
            tty->print_cr("Incompatible str containing cgroup and cpu,cpuacct: %s", p);
          }
        }
      } else if (strstr(p, "cpuacct") != NULL) {
        int matched = sscanf(p, "%d %d %d:%d %s %s",
                             &mountid,
                             &parentid,
                             &major,
                             &minor,
                             tmproot,
                             tmpmount);
        if (matched == 6) {

          cpuacct = new CgroupSubsystem(tmproot, tmpmount);
        }
        else {
          if (PrintContainerInfo) {
            tty->print_cr("Incompatible str containing cgroup and cpuacct: %s", p);
          }
        }
      } else if (strstr(p, "cpu") != NULL) {
        int matched = sscanf(p, "%d %d %d:%d %s %s",
                             &mountid,
                             &parentid,
                             &major,
                             &minor,
                             tmproot,
                             tmpmount);
        if (matched == 6) {
          cpu = new CgroupSubsystem(tmproot, tmpmount);
        }
        else {
          if (PrintContainerInfo) {
            tty->print_cr("Incompatible str containing cgroup and cpu: %s", p);
          }
        }
      }
    }
  }

  fclose(mntinfo);

  if (memory == NULL) {
    if (PrintContainerInfo) {
      tty->print_cr("Required cgroup memory subsystem not found");
    }
    return;
  }
  if (cpuset == NULL) {
    if (PrintContainerInfo) {
      tty->print_cr("Required cgroup cpuset subsystem not found");
    }
    return;
  }
  if (cpu == NULL) {
    if (PrintContainerInfo) {
      tty->print_cr("Required cgroup cpu subsystem not found");
    }
    return;
  }
  if (cpuacct == NULL) {
    if (PrintContainerInfo) {
      tty->print_cr("Required cgroup cpuacct subsystem not found");
    }
    return;
  }

  /*
   * Read /proc/self/cgroup and map host mount point to
   * local one via /proc/self/mountinfo content above
   *
   * 读取 /proc/self/cgroup 并通过上面的 /proc/self/mountinfo 内容将主机挂载点映射到JVM变量上
   *
   * Docker example:
   * 5:memory:/docker/6558aed8fc662b194323ceab5b964f69cf36b3e8af877a14b80256e93aecb044
   *
   * Host example:
   * 5:memory:/user.slice
   *
   * Construct a path to the process specific memory and cpuset
   * cgroup directory.
   *
   * For a container running under Docker from memory example above
   * the paths would be:
   *
   * /sys/fs/cgroup/memory
   *
   * For a Host from memory example above the path would be:
   *
   * /sys/fs/cgroup/memory/user.slice
   *
   */
  cgroup = fopen("/proc/self/cgroup", "r");
  if (cgroup == NULL) {
    if (PrintContainerInfo) {
      tty->print_cr("Can't open /proc/self/cgroup, %s",
                     strerror(errno));
      }
    return;
  }

  while ( (p = fgets(buf, MAXPATHLEN, cgroup)) != NULL) {
    int cgno;
    int matched;
    char *controller;
    char *base;

    /* Skip cgroup number */
    strsep(&p, ":");
    /* Get controller and base */
    controller = strsep(&p, ":");
    base = strsep(&p, "\n");

    if (controller != NULL) {
      if (strstr(controller, "memory") != NULL) {
        memory->set_subsystem_path(base);
      } else if (strstr(controller, "cpuset") != NULL) {
        cpuset->set_subsystem_path(base);
      } else if (strstr(controller, "cpu,cpuacct") != NULL || strstr(controller, "cpuacct,cpu") != NULL) {
        cpu->set_subsystem_path(base);
        cpuacct->set_subsystem_path(base);
      } else if (strstr(controller, "cpuacct") != NULL) {
        cpuacct->set_subsystem_path(base);
      } else if (strstr(controller, "cpu") != NULL) {
        cpu->set_subsystem_path(base);
      }
    }
  }

  fclose(cgroup);

  // We need to update the amount of physical memory now that
  // command line arguments have been processed.
  if ((mem_limit = memory_limit_in_bytes()) > 0) {
    os::Linux::set_physical_memory(mem_limit);
  }

  _is_containerized = true;

}

~~~

`arguments.cpp`

~~~
void Arguments::set_heap_size() {
  julong phys_mem =
    FLAG_IS_DEFAULT(MaxRAM) ? MIN2(os::physical_memory(), (julong)MaxRAM)
                            : (julong)MaxRAM;

  // Convert deprecated flags
  if (FLAG_IS_DEFAULT(MaxRAMPercentage) &&
      !FLAG_IS_DEFAULT(MaxRAMFraction))
    MaxRAMPercentage = 100.0 / MaxRAMFraction;

  if (FLAG_IS_DEFAULT(MinRAMPercentage) &&
      !FLAG_IS_DEFAULT(MinRAMFraction))
    MinRAMPercentage = 100.0 / MinRAMFraction;

  if (FLAG_IS_DEFAULT(InitialRAMPercentage) &&
      !FLAG_IS_DEFAULT(InitialRAMFraction))
    InitialRAMPercentage = 100.0 / InitialRAMFraction;

  // If the maximum heap size has not been set with -Xmx,
  // then set it as fraction of the size of physical memory,
  // respecting the maximum and minimum sizes of the heap.
  if (FLAG_IS_DEFAULT(MaxHeapSize)) {
    julong reasonable_max = (julong)((phys_mem * MaxRAMPercentage) / 100);
    const julong reasonable_min = (julong)((phys_mem * MinRAMPercentage) / 100);
    if (reasonable_min < MaxHeapSize) {
      // Small physical memory, so use a minimum fraction of it for the heap
      reasonable_max = reasonable_min;
    } else {
      // Not-small physical memory, so require a heap at least
      // as large as MaxHeapSize
      reasonable_max = MAX2(reasonable_max, (julong)MaxHeapSize);
    }

    if (!FLAG_IS_DEFAULT(ErgoHeapSizeLimit) && ErgoHeapSizeLimit != 0) {
      // Limit the heap size to ErgoHeapSizeLimit
      reasonable_max = MIN2(reasonable_max, (julong)ErgoHeapSizeLimit);
    }
    if (UseCompressedOops) {
      // Limit the heap size to the maximum possible when using compressed oops
      julong max_coop_heap = (julong)max_heap_for_compressed_oops();

      // HeapBaseMinAddress can be greater than default but not less than.
      if (!FLAG_IS_DEFAULT(HeapBaseMinAddress)) {
        if (HeapBaseMinAddress < DefaultHeapBaseMinAddress) {
          // matches compressed oops printing flags
          log_debug(gc, heap, coops)("HeapBaseMinAddress must be at least " SIZE_FORMAT
                                     " (" SIZE_FORMAT "G) which is greater than value given " SIZE_FORMAT,
                                     DefaultHeapBaseMinAddress,
                                     DefaultHeapBaseMinAddress/G,
                                     HeapBaseMinAddress);
          FLAG_SET_ERGO(size_t, HeapBaseMinAddress, DefaultHeapBaseMinAddress);
        }
      }

      if (HeapBaseMinAddress + MaxHeapSize < max_coop_heap) {
        // Heap should be above HeapBaseMinAddress to get zero based compressed oops
        // but it should be not less than default MaxHeapSize.
        max_coop_heap -= HeapBaseMinAddress;
      }
      reasonable_max = MIN2(reasonable_max, max_coop_heap);
    }
    reasonable_max = limit_by_allocatable_memory(reasonable_max);

    if (!FLAG_IS_DEFAULT(InitialHeapSize)) {
      // An initial heap size was specified on the command line,
      // so be sure that the maximum size is consistent.  Done
      // after call to limit_by_allocatable_memory because that
      // method might reduce the allocation size.
      reasonable_max = MAX2(reasonable_max, (julong)InitialHeapSize);
    }

    log_trace(gc, heap)("  Maximum heap size " SIZE_FORMAT, (size_t) reasonable_max);
    FLAG_SET_ERGO(size_t, MaxHeapSize, (size_t)reasonable_max);
  }

  // If the minimum or initial heap_size have not been set or requested to be set
  // ergonomically, set them accordingly.
  if (InitialHeapSize == 0 || min_heap_size() == 0) {
    julong reasonable_minimum = (julong)(OldSize + NewSize);

    reasonable_minimum = MIN2(reasonable_minimum, (julong)MaxHeapSize);

    reasonable_minimum = limit_by_allocatable_memory(reasonable_minimum);

    if (InitialHeapSize == 0) {
      julong reasonable_initial = (julong)((phys_mem * InitialRAMPercentage) / 100);

      reasonable_initial = MAX3(reasonable_initial, reasonable_minimum, (julong)min_heap_size());
      reasonable_initial = MIN2(reasonable_initial, (julong)MaxHeapSize);

      reasonable_initial = limit_by_allocatable_memory(reasonable_initial);

      log_trace(gc, heap)("  Initial heap size " SIZE_FORMAT, (size_t)reasonable_initial);
      FLAG_SET_ERGO(size_t, InitialHeapSize, (size_t)reasonable_initial);
    }
    // If the minimum heap size has not been set (via -Xms),
    // synchronize with InitialHeapSize to avoid errors with the default value.
    if (min_heap_size() == 0) {
      set_min_heap_size(MIN2((size_t)reasonable_minimum, InitialHeapSize));
      log_trace(gc, heap)("  Minimum heap size " SIZE_FORMAT, min_heap_size());
    }
  }
}

~~~



## reference

[1][java11 arguments.cpp](http://hg.openjdk.java.net/jdk/jdk11/file/1ddf9a99e4ad/src/hotspot/share/runtime/arguments.cpp#l1750)  
[2][java|Java Platform, Standard Edition Tools Reference](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/java.html)  
[3][Cgroup - cpu, cpuacct, cpuset子系统|大彬](https://lessisbetter.site/2020/09/01/cgroup-3-cpu-md/)  





