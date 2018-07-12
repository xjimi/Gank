//
//  MainViewController.swift
//  Gank
//
//  Created by NuGelaLiee on 2018/3/7.
//

import UIKit
import RxSwift
import RxDataSources
import MJRefresh

class MainViewController: BaseViewController {
    let Bag = DisposeBag()
    
    var dataSource: RxTableViewSectionedReloadDataSource<SectionModel<String, TNNews>>?
    lazy var tableView: UITableView = {
        let tv = UITableView.init(frame: .zero, style: .plain)
        tv.estimatedRowHeight = 300
        tv.separatorStyle = .none
        tv.estimatedSectionFooterHeight = 0
        tv.estimatedSectionHeaderHeight = 0
        tv.rowHeight = UITableViewAutomaticDimension
        tv.backgroundColor = UIColor.colorWith(r: 240, g: 240, b: 240)
        tv.register(HomeVeiwCell.self)
        tv.mj_header = MJRefreshNormalHeader()
        tv.register(headerFooterViewClass: HomeHeaderFooterView.self)
        return tv
    }()
    
    var viewModel: GankNewsViewModel!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "干货集中营"
    }
    override func setupSubViews() {
       
        viewModel = GankNewsViewModel(
            input:(headerRefresh: self.tableView.mj_header.rx.refreshing.asDriver(),
                   disposeBag: Bag))
        
        view.addSubview(tableView)
        
        tableView.rx.setDelegate(self).disposed(by: Bag)
        
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let calenderItem = UIBarButtonItem(image: UIImage(named: "calendar"), style: .plain) {
            let Calendar = CalenderController()
            Calendar.title = "历史的年轮"
            Calendar.goodsDate.asObservable()
                .filter {!$0.isEmpty}
                .concatMap {self.viewModel.getNews(to: $0)}
                .bind(to: self.viewModel.tableData)
                .disposed(by: Calendar.disposeBag)
            self.navigationController?.pushViewController(Calendar, animated: true)
        }
        self.navigationItem.rightBarButtonItem = calenderItem
    }
    
    override func setupRxConfig() {
        dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, TNNews>>(configureCell: { (ds, tv, indexPath, element) -> UITableViewCell in
            let cell = tv.dequeue(HomeVeiwCell.self)
            cell.model = element
            return cell
        })
        
        tableView.rx.modelSelected(TNNews.self)
            .subscribeNext { (item) in
                let web = BaseWebViewController()
                web.url = item.url ?? Constant.web.defaultWebSite
                self.navigationController?.pushViewController(web, animated: true)
        }.disposed(by: Bag)
        
        viewModel.tableData.asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(dataSource: dataSource!))
            .disposed(by: Bag)

        viewModel.refreshing
            .drive(tableView.mj_header.rx.endRefreshing)
            .disposed(by: Bag)
    }
    
}

extension MainViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueHeaderFooter(HomeHeaderFooterView.self)
        if let t = dataSource?.sectionModels[section].model {
           header.configTitle(t)
        }
        return header
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 56
    }
}


