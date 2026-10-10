#pragma once

namespace bs {

// Shared by local discovery and the HTTPS certificate's DNS subjectAltName.
inline constexpr char kServiceHostname[] = "batterysentinel";
inline constexpr char kServiceDnsName[] = "batterysentinel.local";

} // namespace bs
