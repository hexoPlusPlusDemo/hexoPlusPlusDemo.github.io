---
title: 修复使用RigidBody2D实现击退效果时的叠加问题
date: 2024-12-09T16:26:00
abbrlink: d863527924a0
tags:
  - 错误解决
categories:
  - 游戏开发
  - Unity
  - U2D
  - 碰撞体
---

在使用RigidBody2D实现击退效果的时候，我的敌人出现了一个奇怪的问题。我不断的攻击，会导致它每次的击退距离变远，我的击退代码如下：
```csharp
 public void Knockback(Vector3 pos){
    if(!canKnokback||isDead) return;
    var direction = (transform.position - pos);
kk    direction.z = 0;
    direction = direction.normalized;
    StartCoroutine(KnockbackCoroutine(direction, KnokbackForce));
}
IEnumerator KnockbackCoroutine(Vector3 direction, float force){
    m_rigidbody2d.AddForce(direction * force, ForceMode2D.Impulse);
    yield return new WaitForSeconds(KnokbackForceDuration);
    isHurt = false;
}
```
起初我怀疑是force的问题，所以我在每次击退前尝试把`m_rigidbody2d.totalforce`设置为零，后来没有作用。于是我联想到这个问题肯定与我的移动代码有关，这是我的移动代码：
```csharp
virtual public void FixedUpdate(){
    if(!isHurt&&!isDead&&canMove){
        Move(m_currentSpeed);
    }
}
protected void Move(float currentSpeed){
    Vector2 position = m_rigidbody2d.position;
    position += m_currentDirection * currentSpeed * Time.fixedDeltaTime;
    m_rigidbody2d.MovePosition(position);
}
```

这个移动代码不会修改刚体的属性，只会进行一个刚体移动。导致我们的刚体速度不会受移动代码影响。而我们的`AddForce`函数是通过修改刚体的`velocity`成员来实现的。但是我们的移动代码优先级高于刚体的自动更新，导致这个没有体现出来。但是在敌人被攻击的时候，移动代码暂时停止工作，导致刚体的移动会生效，就会出现敌人每次被攻击才会累计速度。所以我选择在赋予敌人击退的前将它的速度修改为零。这样就修复了这个问题。代码如下：
```csharp
public void Knockback(Vector3 pos){
    if(!canKnokback||isDead) return;
    var direction = (transform.position - pos);
    direction.z = 0;
    direction = direction.normalized;
    m_rigidbody2d.velocity = Vector2.zero;
    StartCoroutine(KnockbackCoroutine(direction, KnokbackForce));
}
IEnumerator KnockbackCoroutine(Vector3 direction, float force){
    m_rigidbody2d.AddForce(direction * force, ForceMode2D.Impulse);
    yield return new WaitForSeconds(KnokbackForceDuration);
    isHurt = false;
}
```