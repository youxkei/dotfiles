# This file has been generated by node2nix 1.8.0. Do not edit!

{nodeEnv, fetchurl, fetchgit, globalBuildInputs ? []}:

let
  sources = {
    "command-exists-1.2.6" = {
      name = "command-exists";
      packageName = "command-exists";
      version = "1.2.6";
      src = fetchurl {
        url = "https://registry.npmjs.org/command-exists/-/command-exists-1.2.6.tgz";
        sha512 = "Qst/zUUNmS/z3WziPxyqjrcz09pm+2Knbs5mAZL4VAE0sSrNY1/w8+/YxeHcoBTsO6iojA6BW7eFf27Eg2MRuw==";
      };
    };
    "commander-2.20.3" = {
      name = "commander";
      packageName = "commander";
      version = "2.20.3";
      src = fetchurl {
        url = "https://registry.npmjs.org/commander/-/commander-2.20.3.tgz";
        sha512 = "GpVkmM8vF2vQUkj2LvZmD35JxeJOLCwJ9cUkugyk2nuhbv3+mJvpLYYt+0+USMxE+oj+ey/lJEnhZw75x/OMcQ==";
      };
    };
    "crypto-random-string-1.0.0" = {
      name = "crypto-random-string";
      packageName = "crypto-random-string";
      version = "1.0.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/crypto-random-string/-/crypto-random-string-1.0.0.tgz";
        sha1 = "a230f64f568310e1498009940790ec99545bca7e";
      };
    };
    "fs-extra-7.0.1" = {
      name = "fs-extra";
      packageName = "fs-extra";
      version = "7.0.1";
      src = fetchurl {
        url = "https://registry.npmjs.org/fs-extra/-/fs-extra-7.0.1.tgz";
        sha512 = "YJDaCJZEnBmcbw13fvdAM9AwNOJwOzrE4pqMqBq5nFiEqXUqHwlK4B+3pUw6JNvfSPtX05xFHtYy/1ni01eGCw==";
      };
    };
    "graceful-fs-4.2.4" = {
      name = "graceful-fs";
      packageName = "graceful-fs";
      version = "4.2.4";
      src = fetchurl {
        url = "https://registry.npmjs.org/graceful-fs/-/graceful-fs-4.2.4.tgz";
        sha512 = "WjKPNJF79dtJAVniUlGGWHYGz2jWxT6VhN/4m1NdkbZ2nOsEF+cI1Edgql5zCRhs/VsQYRvrXctxktVXZUkixw==";
      };
    };
    "jsonfile-4.0.0" = {
      name = "jsonfile";
      packageName = "jsonfile";
      version = "4.0.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/jsonfile/-/jsonfile-4.0.0.tgz";
        sha1 = "8771aae0799b64076b76640fca058f9c10e33ecb";
      };
    };
    "p-debounce-1.0.0" = {
      name = "p-debounce";
      packageName = "p-debounce";
      version = "1.0.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/p-debounce/-/p-debounce-1.0.0.tgz";
        sha1 = "cb7f2cbeefd87a09eba861e112b67527e621e2fd";
      };
    };
    "temp-dir-1.0.0" = {
      name = "temp-dir";
      packageName = "temp-dir";
      version = "1.0.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/temp-dir/-/temp-dir-1.0.0.tgz";
        sha1 = "0a7c0ea26d3a39afa7e0ebea9c1fc0bc4daa011d";
      };
    };
    "tempy-0.2.1" = {
      name = "tempy";
      packageName = "tempy";
      version = "0.2.1";
      src = fetchurl {
        url = "https://registry.npmjs.org/tempy/-/tempy-0.2.1.tgz";
        sha512 = "LB83o9bfZGrntdqPuRdanIVCPReam9SOZKW0fOy5I9X3A854GGWi0tjCqoXEk84XIEYBc/x9Hq3EFop/H5wJaw==";
      };
    };
    "unique-string-1.0.0" = {
      name = "unique-string";
      packageName = "unique-string";
      version = "1.0.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/unique-string/-/unique-string-1.0.0.tgz";
        sha1 = "9e1057cca851abb93398f8b33ae187b99caec11a";
      };
    };
    "universalify-0.1.2" = {
      name = "universalify";
      packageName = "universalify";
      version = "0.1.2";
      src = fetchurl {
        url = "https://registry.npmjs.org/universalify/-/universalify-0.1.2.tgz";
        sha512 = "rBJeI5CXAlmy1pV+617WB9J63U6XcazHHF2f2dbJix4XzpUF0RS3Zbj0FGIOCAva5P/d/GBOYaACQ1w+0azUkg==";
      };
    };
    "vscode-jsonrpc-6.0.0" = {
      name = "vscode-jsonrpc";
      packageName = "vscode-jsonrpc";
      version = "6.0.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/vscode-jsonrpc/-/vscode-jsonrpc-6.0.0.tgz";
        sha512 = "wnJA4BnEjOSyFMvjZdpiOwhSq9uDoK8e/kpRJDTaMYzwlkrhG1fwDIZI94CLsLzlCK5cIbMMtFlJlfR57Lavmg==";
      };
    };
    "vscode-languageserver-5.3.0-next.10" = {
      name = "vscode-languageserver";
      packageName = "vscode-languageserver";
      version = "5.3.0-next.10";
      src = fetchurl {
        url = "https://registry.npmjs.org/vscode-languageserver/-/vscode-languageserver-5.3.0-next.10.tgz";
        sha512 = "QL7Fe1FT6PdLtVzwJeZ78pTic4eZbzLRy7yAQgPb9xalqqgZESR0+yDZPwJrM3E7PzOmwHBceYcJR54eQZ7Kng==";
      };
    };
    "vscode-languageserver-protocol-3.16.0" = {
      name = "vscode-languageserver-protocol";
      packageName = "vscode-languageserver-protocol";
      version = "3.16.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/vscode-languageserver-protocol/-/vscode-languageserver-protocol-3.16.0.tgz";
        sha512 = "sdeUoAawceQdgIfTI+sdcwkiK2KU+2cbEYA0agzM2uqaUy2UpnnGHtWTHVEtS0ES4zHU0eMFRGN+oQgDxlD66A==";
      };
    };
    "vscode-languageserver-types-3.16.0" = {
      name = "vscode-languageserver-types";
      packageName = "vscode-languageserver-types";
      version = "3.16.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/vscode-languageserver-types/-/vscode-languageserver-types-3.16.0.tgz";
        sha512 = "k8luDIWJWyenLc5ToFQQMaSrqCHiLwyKPHKPQZ5zz21vM+vIVUSvsRpcbiECH4WR88K2XZqc4ScRcZ7nk/jbeA==";
      };
    };
    "vscode-textbuffer-1.0.0" = {
      name = "vscode-textbuffer";
      packageName = "vscode-textbuffer";
      version = "1.0.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/vscode-textbuffer/-/vscode-textbuffer-1.0.0.tgz";
        sha512 = "zPaHo4urgpwsm+PrJWfNakolRpryNja18SUip/qIIsfhuEqEIPEXMxHOlFPjvDC4JgTaimkncNW7UMXRJTY6ow==";
      };
    };
    "vscode-uri-1.0.8" = {
      name = "vscode-uri";
      packageName = "vscode-uri";
      version = "1.0.8";
      src = fetchurl {
        url = "https://registry.npmjs.org/vscode-uri/-/vscode-uri-1.0.8.tgz";
        sha512 = "obtSWTlbJ+a+TFRYGaUumtVwb+InIUVI0Lu0VBUAPmj2cU5JutEXg3xUE0c2J5Tcy7h2DEKVJBFi+Y9ZSFzzPQ==";
      };
    };
  };
in
{
  typescript = nodeEnv.buildNodePackage {
    name = "typescript";
    packageName = "typescript";
    version = "4.1.3";
    src = fetchurl {
      url = "https://registry.npmjs.org/typescript/-/typescript-4.1.3.tgz";
      sha512 = "B3ZIOf1IKeH2ixgHhj6la6xdwR9QrLC5d1VKeCSY4tvkqhF2eqd9O7txNlS0PO3GrBAFIdr3L1ndNwteUbZLYg==";
    };
    buildInputs = globalBuildInputs;
    meta = {
      description = "TypeScript is a language for application scale JavaScript development";
      homepage = https://www.typescriptlang.org/;
      license = "Apache-2.0";
    };
    production = true;
    bypassCache = true;
    reconstructLock = true;
  };
  typescript-language-server = nodeEnv.buildNodePackage {
    name = "typescript-language-server";
    packageName = "typescript-language-server";
    version = "0.5.1";
    src = fetchurl {
      url = "https://registry.npmjs.org/typescript-language-server/-/typescript-language-server-0.5.1.tgz";
      sha512 = "60Kguhwk/R1BB4pEIb6B9C7Ix7JzLzYnsODlmorYMPjMeEV0rCBqTR6FGAj4wVw/eHrHcpwLENmmURKUd8aybA==";
    };
    dependencies = [
      sources."command-exists-1.2.6"
      sources."commander-2.20.3"
      sources."crypto-random-string-1.0.0"
      sources."fs-extra-7.0.1"
      sources."graceful-fs-4.2.4"
      sources."jsonfile-4.0.0"
      sources."p-debounce-1.0.0"
      sources."temp-dir-1.0.0"
      sources."tempy-0.2.1"
      sources."unique-string-1.0.0"
      sources."universalify-0.1.2"
      sources."vscode-jsonrpc-6.0.0"
      sources."vscode-languageserver-5.3.0-next.10"
      sources."vscode-languageserver-protocol-3.16.0"
      sources."vscode-languageserver-types-3.16.0"
      sources."vscode-textbuffer-1.0.0"
      sources."vscode-uri-1.0.8"
    ];
    buildInputs = globalBuildInputs;
    meta = {
      description = "Language Server Protocol (LSP) implementation for TypeScript using tsserver";
      homepage = "https://github.com/theia-ide/typescript-language-server#readme";
      license = "Apache-2.0";
    };
    production = true;
    bypassCache = true;
    reconstructLock = true;
  };
}