import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  webpack: (config) => {
    // Prevent errors from packages that expect 'canvas' in Node
    config.resolve.alias.canvas = false;
    return config;
  },
};

export default nextConfig;
