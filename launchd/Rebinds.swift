
// This file is licensed under the BSD-3 Clause License
// Copyright 2022 © ElleKit Team

import Foundation

class Rebinds {
    
    static var shared = Rebinds()
    
    typealias SpawnBody = @convention(c) (
        UnsafeMutablePointer<pid_t>?,
        UnsafePointer<CChar>?,
        UnsafePointer<posix_spawn_file_actions_t?>?,
        UnsafePointer<posix_spawnattr_t?>?,
        UnsafePointer<UnsafeMutablePointer<CChar>?>?,
        UnsafePointer<UnsafeMutablePointer<CChar>?>?
    ) -> Int32
    
    var posix_spawn = dlsym(dlopen(nil, RTLD_NOW), "posix_spawn")!
    var posix_spawnp = dlsym(dlopen(nil, RTLD_NOW), "posix_spawnp")!
    
    var posix_spawn_replacement = dlsym(dlopen(nil, RTLD_LAZY), "posix_spawn_replacement")!
    var posix_spawnp_replacement = dlsym(dlopen(nil, RTLD_LAZY), "posix_spawnp_replacement")!
    var sandbox_check_replacement = dlsym(dlopen(nil, RTLD_LAZY), "hook_sandbox_check")!
    
    var posix_spawn_orig_ptr: UnsafeMutableRawPointer? = dlsym(dlopen("/usr/lib/system/libsystem_kernel.dylib", RTLD_NOW), "posix_spawn")!
    var posix_spawn_orig: SpawnBody {
        unsafeBitCast(posix_spawn_orig_ptr!, to: SpawnBody.self)
    }
    var posix_spawnp_orig_ptr: UnsafeMutableRawPointer? = dlsym(dlopen("/usr/lib/libSystem.B.dylib", RTLD_NOW), "posix_spawnp")!
    var posix_spawnp_orig: SpawnBody {
        unsafeBitCast(posix_spawnp_orig_ptr!, to: SpawnBody.self)
    }
    
    var usedFishhook = false
    
    func rebind() {
        self.usedFishhook = true
                    
        var rebindinds = [
            rebinding(name: strdup("posix_spawn"), replacement: posix_spawn_replacement, replaced: nil),
            rebinding(name: strdup("posix_spawnp"), replacement: posix_spawnp_replacement, replaced: nil),
            rebinding(name: strdup("sandbox_check_by_audit_token"), replacement: sandbox_check_replacement, replaced: nil)
        ]
        
        let index = (0..<_dyld_image_count())
            .filter {
                String(cString: _dyld_get_image_name($0))
                    .contains( ProcessInfo.processInfo.processName)
            }
            .first ?? 1
        
        tprint("rebindinds starting \(index) \(String(cString: _dyld_get_image_name(index)))")
        
        _ = rebindinds.withUnsafeMutableBufferPointer { buf in
            rebind_symbols_image(
                unsafeBitCast(_dyld_get_image_header(index), to: UnsafeMutableRawPointer.self),
                _dyld_get_image_vmaddr_slide(index),
                buf.baseAddress, 3
            )
        }
    }
    
    func hook() {
        if let orig = pspawn.hook(self.posix_spawn, self.posix_spawn_replacement),
           let origp = pspawn.hook(self.posix_spawnp, self.posix_spawnp_replacement) {
            self.usedFishhook = false
            self.posix_spawn_orig_ptr = orig
            self.posix_spawnp_orig_ptr = origp
            if let orig = self.posix_spawn_orig_ptr, let porig = self.posix_spawnp_orig_ptr {
                tprint("orig is not nil now \(orig) \(porig)")
            }
        } else {
            tprint("hook failed. shoot")
            rebind()
        }
    }
    
    func performHooks() {
        #if os(macOS)
        hook()
        #else
        tprint("using fishhook for launchd/proxy hooks")
        rebind()
        #endif
    }
}
