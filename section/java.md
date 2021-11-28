## 简介


## 




## 附录


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