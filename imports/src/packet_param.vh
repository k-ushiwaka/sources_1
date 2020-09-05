// Soruce Mac Addres
localparam  ETH_SRC_MAC_0 = 8'h12;
localparam  ETH_SRC_MAC_1 = 8'ha4;
localparam  ETH_SRC_MAC_2 = 8'he9;
localparam  ETH_SRC_MAC_3 = 8'h54;
localparam  ETH_SRC_MAC_4 = 8'h4d;
localparam  ETH_SRC_MAC_5 = 8'h2c;
// destination Mac Addres
localparam  ETH_DST_MAC_0 = 8'hff;
localparam  ETH_DST_MAC_1 = 8'hff;
localparam  ETH_DST_MAC_2 = 8'hff;
localparam  ETH_DST_MAC_3 = 8'hff;
localparam  ETH_DST_MAC_4 = 8'hff;
localparam  ETH_DST_MAC_5 = 8'hff;
// Flame Type
localparam  ETH_TYPE_0  = 8'h00;
localparam  ETH_TYPE_1  = 8'h08;

// IPv4 packet format //

// IP version & header_length
localparam  IP_VERSION_LENGTH = {4'h4,4'h5}; // [7:4] version [3:0] Header length
// IP Type of Service
localparam  IP_DSCP_ECN = 8'h00;
// IP Identification
localparam  IP_IDENTIFICATION_0 = 8'h00;
localparam  IP_IDENTIFICATION_1 = 8'h00;
// IP Flags & Fragment Offset
localparam  IP_FLAGS_0  =  8'h00;
localparam  IP_FLAGS_1  =  8'h00;
// IP Time to Live
localparam  IP_TTL      = 8'h10;
// IP Protcol
localparam  IP_PROTOCOL = 8'h11; //UDP
// IP Source IP Address
localparam  IP_SRC_ADDR_0 = 8'h41;
localparam  IP_SRC_ADDR_1 = 8'h01;
localparam  IP_SRC_ADDR_2 = 8'ha8;
localparam  IP_SRC_ADDR_3 = 8'hc0;
// IP Destination IP Address
localparam  IP_DST_ADDR_0 = 8'h32;
localparam  IP_DST_ADDR_1 = 8'h01;
localparam  IP_DST_ADDR_2 = 8'ha8;
localparam  IP_DST_ADDR_3 = 8'hc0;
// IP Options

// Other //
localparam  IP_HEADER_BYTE = 20;
localparam  UDP_HEADER_BYTE = 8;
localparam  ETH_HEADER_BYTE = 14;