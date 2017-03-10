//
//  ViewController.swift
//  SwiftGCD
//
//  Created by liuxiaoliang on 17/3/8.
//  Copyright © 2017年 pingan. All rights reserved.
//

let imageUrl = "https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1489036024642&di=cb7ef8c204dc78235f9f32f8c7498b24&imgtype=0&src=http%3A%2F%2Fimg3.duitang.com%2Fuploads%2Fitem%2F201602%2F18%2F20160218023812_J4uUZ.thumb.700_0.jpeg"

import UIKit

class ViewController: UIViewController {
    
    var count = 100
    let condition = NSCondition()
    let queue = OperationQueue()
    
    @IBOutlet weak var image: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //NSThread使用
        //threadTest()
        
        //NSOperation使用
        operationTest()
        
        
        //GCD使用
        //GCDTest()
        
    }
}


fileprivate extension ViewController{
    
    
    
    func threadTest(){
        
        //1、类方法创建线程并且开始运行线程，无法对线程进行更详细的设置
        Thread.detachNewThreadSelector(#selector(action), toTarget: self, with: nil)
        Thread.detachNewThread {
            //block形式
        }
        
        //2、实例方法创建线程,操作前可以设置线程的优先级
        let thread = Thread(target: self, selector: #selector(action2), object: nil)
        thread.name = "lxl125z"
        thread.threadPriority = 0.5  //设置优先级
        thread.start()
        
        //3、隐式创建并启动线程
        performSelector(inBackground: #selector(action2), with: nil)
        
        
        // 线程wait和signal演示
        //Thread.detachNewThreadSelector(#selector(action3), toTarget: self, with: nil)
        
    }
    
    @objc func action(){
        print("action执行了",Thread.current,Thread.isMainThread)
        let data = NSData(contentsOf: NSURL(string: imageUrl) as! URL)
        if let data = data{
            let image = UIImage(data: data as Data)
            performSelector(onMainThread: #selector(updateUI), with: image, waitUntilDone: true)
        }
    }
    
    @objc func updateUI(image:UIImage){
        self.image.image = image;
        print("主线程刷新UI")
    }
    
    @objc func action2(){
        //condition.wait()
        while (true) {
            //condition.lock()        //加锁
            
            if count>0 {
                Thread.sleep(forTimeInterval: 0.1)
                count -= 1
                print("action2执行了",Thread.current,Thread.isMainThread)
            }else{
                break
            }
            //condition.unlock()
        }
    }
    
    @objc func action3(){
        print("action3执行后去唤醒执行action2的两个线程，记着打开  condition.wait()")
        condition.signal()
        
    }
}

fileprivate extension ViewController{
    
    func operationTest(){
        //PS：Operation一般使用它的子类
        //子类NSInvocationOperation(Swift不支持)
        
        //使用方式
        //1、使用子类BlockOperation
        //operationTest_blockOperation()
        
        //2、OperationQueue队列
        
        operationTest_OperationQueue()
        
        //设施依赖关系
        //operationTest_DependencyRelationship()
        
        //设置Operation的优先级
        //operationTest_Priority()
        
        //等待Operation完成‘
        //operationTest_wait()
    }
    
    
    func operationTest_blockOperation(){
        
        //只要BlockOperation封装的操作数 > 1,就会异步执行操作,但是不会无限制的创建线程
        let blockOpe = BlockOperation()
        blockOpe.addExecutionBlock {
            print("BlockOperation执行了",Thread.current)
        }
        blockOpe.queuePriority = .low
        blockOpe.addExecutionBlock {
            print("BlockOperation2执行了",Thread.current)
        }
        blockOpe.start()
        
    }
    
    
    func  operationTest_OperationQueue(){
        
        //设置最大并发数
        queue.maxConcurrentOperationCount = 1
        queue.addOperation {
            for _ in 0...5{
                print("OperationQueue1执行了",Thread.current)
                
            }
        }
        queue.addOperation {
            print("OperationQueue2执行了",Thread.current)
        }
        queue.addOperation {
            print("OperationQueue3执行了",Thread.current)
        }

        let blockOpe = BlockOperation()
        blockOpe.addExecutionBlock {
            print("BlockOperation执行了",Thread.current)
        }
        queue.addOperation(blockOpe)
    }
    
    func operationTest_DependencyRelationship(){
        
        //设置依赖关系
        let blockOpe1 = BlockOperation()
        blockOpe1.addExecutionBlock {
            print("blockOpe1执行了")
        }
        let blockOpe2 = BlockOperation()
        blockOpe2.addExecutionBlock {
            print("blockOpe2执行了")
        }
        blockOpe1.addDependency(blockOpe2)
        queue.addOperation(blockOpe1)
        queue.addOperation(blockOpe2)
        
    }
    
    func operationTest_Priority(){
        
        
        //设置依赖关系(依赖关系和优先级无关)
        let blockOpe1 = BlockOperation()
        blockOpe1.addExecutionBlock {
            print("blockOpe1执行了")
        }
        let blockOpe2 = BlockOperation()
        blockOpe2.queuePriority = .high
        blockOpe2.addExecutionBlock {
            print("blockOpe2执行了")
        }
        blockOpe1.addDependency(blockOpe2)
        queue.addOperation(blockOpe1)
        queue.addOperation(blockOpe2)
    }
    
    func operationTest_wait(){
        let blockOpe1 = BlockOperation()
        
        blockOpe1.addExecutionBlock {
            print("blockOpe1执行了",Thread.current)
        }
        let blockOpe2 = BlockOperation()
        blockOpe2.queuePriority = .high
        blockOpe2.addExecutionBlock {
            blockOpe1.waitUntilFinished()    //阻塞当前线程直到此任务执行完毕
            print("blockOpe2执行了",Thread.current)
        }
        
        queue.addOperation(blockOpe1)
        queue.addOperation(blockOpe2)
        
    }
    
    
    @IBAction func cancelOperation(_ sender: UIButton) {
        
        queue.cancelAllOperations() //取消队列所有任务
    }
    
    @IBAction func pauseAndResumeOperation(_ sender: UIButton) {
        if sender.tag == 100{
            queue.isSuspended = true    //暂停队列
        }else{
            queue.isSuspended = false  //恢复队列
        }
        
        
        
    }
    
}

fileprivate extension ViewController{

    func GCDTest(){
        
        let gcdQueue = DispatchQueue(label: "com.pingan.test")
        for index in 0...100{
            gcdQueue.async {
                print("任务1执行了",Thread.current,index) //异步开一条线程，顺序执行，同步不开线程
                
            }
        }
    }


}
