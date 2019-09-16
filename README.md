# envoy-dubbo

# 这里记录一下dubbo使用envoy的相关流程，步骤

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

# 使用envoy来做代理

