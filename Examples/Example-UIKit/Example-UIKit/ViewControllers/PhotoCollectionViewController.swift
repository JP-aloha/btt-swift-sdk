//
//  PhotoCollectionViewController.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 8/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import BlueTriangle
import UIKit

typealias CollectionViewLayoutBuilder = () -> UICollectionViewLayout

struct LayoutBuilder {
    let fractionalItemWidth: CGFloat
    let fractionalItemHeight: CGFloat

    func buildLayout() -> UICollectionViewLayout {
        let provider: UICollectionViewCompositionalLayoutSectionProvider = { _, _ in
            // Item
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fractionalItemWidth),
                                                 heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // Group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .fractionalWidth(fractionalItemWidth))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            // Section
            let section = NSCollectionLayoutSection(group: group)
            return section
        }

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        return UICollectionViewCompositionalLayout(sectionProvider: provider, configuration: config)
    }

    static let standard: Self = {
        .init(fractionalItemWidth: (1.0 / 3.0),
              fractionalItemHeight: 1.0)
    }()
}

final class PhotoCollectionViewController: UIViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<SingleSection, Photo>
    typealias Snapshot = NSDiffableDataSourceSnapshot<SingleSection, Photo>
    typealias CellRegistration = UICollectionView.CellRegistration<PhotoCell, Photo>

    // Collection View
    private let layoutBuilder: LayoutBuilder
    private lazy var dataSource = makeDataSource(for: collectionView)

    // Data Loading
    private let jsonPlaceholder: PlaceholderServiceProtocol
    private let imageLoader: ImageLoading
    private var loadingTask: Task<Void, Never>?

    // Retain timer
    private var timer: BTTimer?

    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layoutBuilder.buildLayout())
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    init(jsonPlaceholder: PlaceholderServiceProtocol, imageLoader: ImageLoading, layoutBuilder: LayoutBuilder = .standard) {
        self.jsonPlaceholder = jsonPlaceholder
        self.imageLoader = imageLoader
        self.layoutBuilder = layoutBuilder
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        loadingTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Start timer and retain reference to it
        let page = Page(pageName: "Album_Photos",
                        brandValue: 0.5,
                        pageType: "Page_Type",
                        referringURL: "https://mobelux.com/z",
                        url: "https://mobelux.com/photos",
                        customVariables: nil,
                        customCategories: nil,
                        customNumbers: nil)
        timer = BlueTriangle.startTimer(page: page)

        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        fetchData()
    }

    // MARK: - Networking

    private func fetchData() {
        loadingTask = Task {
            do {
                //intentionally delayed first API call by 5 Sec to check network call relative start time
                if #available(iOS 16.0, *) {
                    try await Task.sleep(for: .seconds(5))
                } else {
                    try await Task.sleep(nanoseconds: 5 * 1_000_000_000)
                }
                
                let albums = try await jsonPlaceholder.fetchAlbums()
                guard let album = albums.first else {
                    return
                }
                let photos = try await jsonPlaceholder.fetchPhotos(albumId: album.id)

                let snapshot = SingleSection.makeInitialSnapshot(for: photos)

                // End timer after initial view content has finished loading
                await imageLoader.setCompletion { [weak self] in
                    if let timer = self?.timer {
                        BlueTriangle.endTimer(timer)
                        self?.timer = nil
                    }
                }
                
                await dataSource.apply(snapshot)

                loadingTask?.cancel()
                loadingTask = nil
            } catch {
                handleError(error)
            }
        }
    }

    private func handleError(_ error: Error) {
        print("ERROR: \(error)")

        // End timer
        if let timer = timer {
            BlueTriangle.endTimer(timer)
        }
    }
}

// MARK: - CollectionView Support
private extension PhotoCollectionViewController {
    private func makeCellRegistration() -> CellRegistration {
        CellRegistration { [weak self] cell, indexPath, photo in
            self?.configure(cell: cell, with: photo)
        }
    }

    private func configure(cell: PhotoCell, with photo: Photo) {
        cell.photo = photo
        cell.render(.loading)
        cell.loadingTask = Task {
            do {
                let image = try await imageLoader.load(photo.thumbnailUrl)
                guard cell.photo?.id == photo.id else {
                    return
                }

                let viewState: ViewState<UIImage> = image != nil ? .loaded(image!) : .empty
                cell.render(viewState)
            } catch {
                cell.render(.errror(error))
            }
        }
    }

    func makeDataSource(
        for collectionView: UICollectionView
    ) -> UICollectionViewDiffableDataSource<SingleSection, Photo> {
        let cellRegistration = makeCellRegistration()
        return UICollectionViewDiffableDataSource(
            collectionView: collectionView,
            cellProvider: { collectionView, indexPath, item in
                collectionView.dequeueConfiguredReusableCell(
                    using: cellRegistration,
                    for: indexPath,
                    item: item
                )
            })
    }
}

// MARK: - UICollectionViewDelegate
extension PhotoCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let photo = dataSource.itemIdentifier(for: indexPath) else {
            return
        }

        let detailViewController = PhotoDetailViewController(imageLoader: imageLoader, photo: photo)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}
