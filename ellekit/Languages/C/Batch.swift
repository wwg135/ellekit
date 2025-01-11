
// This file is licensed under the BSD-3 Clause License
// Copyright 2022 © ElleKit Team

import Foundation

#if SWIFT_PACKAGE
import ellekitc
#endif

enum FunctionHookErrors: Error {
    case allocationFailure
    case protectionFailure
}

public func hookFunctions(_ hooks: [(destination: UnsafeMutableRawPointer, replacement: UnsafeMutableRawPointer, orig: UnsafeMutablePointer<UnsafeMutableRawPointer?>?)], _ count: Int) throws -> Bool {
    
    var origPageAddress: mach_vm_address_t = 0
    let krt1 = mach_vm_allocate(mach_task_self_, &origPageAddress, UInt64(vm_page_size), VM_FLAGS_ANYWHERE)

    guard krt1 == KERN_SUCCESS else { throw FunctionHookErrors.allocationFailure }

    let krt2 = mach_vm_protect(mach_task_self_, origPageAddress, UInt64(vm_page_size), 0, VM_PROT_READ | VM_PROT_WRITE)

    guard krt2 == KERN_SUCCESS else { throw FunctionHookErrors.protectionFailure }

    for targetHook in hooks {

        let target = targetHook.destination.makeReadable()

        let orig: UnsafeMutableRawPointer? = hook(targetHook.destination, targetHook.replacement)
        
        if let orig, targetHook.orig != nil {
            targetHook.orig?.pointee = orig.makeCallable()
        }

        if let orig {
            print("[+] ellekit: Performed one hook in LHHookFunctions from \(String(describing: target)) with orig at \(String(describing: orig))")
        } else {
            print("[+] ellekit: Performed one hook in LHHookFunctions from \(String(describing: target)) with no orig")
        }
    }

    let krt3 = mach_vm_protect(mach_task_self_, origPageAddress, UInt64(vm_page_size), 0, VM_PROT_READ | VM_PROT_EXECUTE)
    guard krt3 == KERN_SUCCESS else { throw FunctionHookErrors.protectionFailure }

    return true
}
