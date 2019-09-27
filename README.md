# envoy-dubbo

# 背景
现在有不少用户都在使用dubbo，但是如何把dubbo应用到istio里面还没找到具体案例。原因是envoy的dubbo插件还不完善，只有简单的功能：按method，header匹配然后路由。
限速，熔断等功能都还没有实现。因此在网络上没有dubbo使用envoy作为代理的例子。这里我们先搭建一个dubbo的例子，然后尝试使用我们改造过的envoy来代理dubbo。

# 架构
dubbo consummer -> envoy -> dubbo provider

# dubbo 服务搭建

```
git clone https://github.com/apache/dubbo-samples.git

cd dubbo-samples-api

mvn clean package
```

以上步骤进行构建。

注意，例子使用zookeeper来做服务发现，需要我们自己搭建zk。这里我直接用zk的dock镜像来搭建服务。zk的配置和启动脚本放在zookeeper目录下。

启动provider：
```
mvn -Djava.net.preferIPv4Stack=true -Dexec.mainClass=org.apache.dubbo.samples.provider.Application exec:java
```

启动consummer：
```
mvn -Djava.net.preferIPv4Stack=true -Dexec.mainClass=org.apache.dubbo.samples.client.Application exec:java
```

这时可以看到consummer打印了“hi,dubbo".

# dubbo 直连服务搭建

在上面的例子里面，dubbo的provider和consumer不是直连的，是通过zk来获取服务地址的。这种情况下没法加入envoy代理。所以我们尝试搭建一个直连的服务。
查看dubbo-samples的代码，发现有直连的例子：dubbo-samples-direct.

```
cd dubbo-samples-direct

mvn clean package
```
然后启动provider:

```
mvn -Djava.net.preferIPv4Stack=true -Dexec.mainClass=org.apache.dubbo.samples.direct.DirectProvider exec:java
```

再启动consummer：
```
mvn -Djava.net.preferIPv4Stack=true -Dexec.mainClass=org.apache.dubbo.samples.direct.DirectConsumer exec:java
```

但是没有成功，提示可能是group或者version mismatch。于是修改src/main/resource/dubbo-direct-consumer.xml以及dubbo-direct-provider.xml,去掉groups以及version。
其实两个文件的group和version是对得上的，不知道哪里有问题。
__这里注意的是：修改xml文件后，必须重新执行mvn clean package，不然不会生效__(java新手，不知道是啥原因)

最后重新启动provider和consumer，直连成功

# dubbo-consumer -> envoy (官方dubbo-filter) -> dubbo-provider 

使用envoy的master版本，本地编译后运行（配置文件在envoy-proxy目录）。
注意这里有几个修改：
- envoy 监听20881 端口，cluster配置为20880端口（即dubbo-provider的监听端口）
- 修改dubbo-consumer的xml文件，使其请求20881端口
- envoy配置里面，dubbo-filter的interface match规则要匹配代码里面的interface名字

启动envoy，provider，再执行consumer，发现请求成功。


# dubbo-consumer -> envoy (我们修改过的envoy和dubbo-filter) -> dubbo-provider 

我们改造过的envoy可以提供基于http-connection-manager的通用协议注册框架，新的协议只需要开发封装解析功能即可接入，不用需要单独为新协议开发一整套的filter流程，包括路由，匹配等。
对于dubbo协议，envoy原来已经有一个dubbo的filter，封装解析功能是全的，只是匹配功能还不全,为了把dubbo加入我们的通用协议注册框架，我们把原来的dubbofilter移植过来（去掉原来的路由功能，主要留下包解析的功能)
使用新的dubbo-filter，可以成功使服务联调。
相关配置位于http_dubbo_proxy目录。
