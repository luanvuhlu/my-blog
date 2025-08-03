Tôi đã làm cho một dự án nhỏ về quản lý marketing. Dự án có quy mô không lớn, nhưng có một số tính năng thực sự gây khó khăn cho tôi.

Trong dự án, dữ liệu tập trung ở các bảng liên quan đến company, nơi lưu trữ thông tin về các công ty. Số lượng bản ghi khoảng 500k cho mỗi client. Chưa hết, mỗi công ty có thể có nhiều tags, nhiều ngành nghề và nhiều chi nhánh.

Theo mong muốn của khách hàng, họ muốn trang web hiển thị càng nhiều thông tin càng tốt, đồng thời cũng muốn có thể lọc và tìm kiếm thông tin nhiều nhất có thể.

Việc này dẫn đến vấn đề, việc truy vấn dữ liệu trở nên rất chậm chạp, đặc biệt là khi điều kiện lọc và tìm kiếm trở nên phức tạp, dẫn đến việc phải join nhiều bảng.

## Cấu trúc dữ liệu

Thông tin các bảng như sau:

![Database Schema](/static/img/upload_folder/2025/08/Screenshot 2025-08-03 021340.webp)

Dữ liệu xoay quanh 3 bảng chính: company, tag và industry. Mỗi công ty có thể có nhiều tags và nhiều industry. Như bạn có thể thấy, khi số lượng bản ghi của bảng company tăng lên, việc join các bảng này trở nên khó khăn hơn. Sau khi áp dụng nhiều biện pháp tối ưu code và cơ sở dữ liệu, tôi đã có thể cải thiện hiệu suất truy vấn nhưng kết quả vẫn chưa đạt yêu cầu.

## Vấn đề hiệu suất

Với request không có điều kiện lọc, API trả về trong **264ms**. Có thể chấp nhận được. Không khó hiểu vì nếu không có điều kiện lọc, chỉ cần join các bảng với nhau là có thể lấy được dữ liệu.
Nhưng khi có điều kiện lọc với tag hoặc industry, thời gian tăng lên đáng kể.

Cần **2,027ms** để trả về kết quả với điều kiện lọc với tag hoặc industry.  
Khi lọc với cả hai, thời gian tăng lên **3,402ms**.  
Rất khó chấp nhận cho người dùng nếu mỗi khi mở trang danh sách công ty, họ phải đợi lâu như vậy.

## Giải pháp sử dụng Cache

Lúc này, tôi nghĩ ngay cần phải sử dụng cache để giảm độ trễ. Một giải pháp đơn giản và hiệu quả trong trường hợp này là sử dụng Redis để cache response. Bằng cách này, ta có thể giảm response time một cách đáng kể. Spring Cache cung cấp một cách dễ dàng để tích hợp Redis.

Nhưng trước tiên, phải sửa lại một chút trong code để có thể áp dụng cache.

Code hiện tại của tôi như sau:

```java
public interface CompanyService {
  PagedResponse<CompanyResponse> getAllCompanies(String name, String industryName, String tagName, Pageable pageable);
}
```

Vì mỗi company thuộc về một client riêng. Nếu không sử dụng cache, việc query theo client ở bên trong sẽ không có vấn đề gì (việc chọn client sẽ được thực hiện bên trong). Nhưng khi sử dụng cache, ta cần phải đảm bảo rằng mỗi client có một cache riêng biệt để tránh xung đột dữ liệu.

```java
public interface ClientCompanyService {
  PagedResponse<CompanyResponse> getAllCompanies(Long clientId, String name, String industryName, String tagName, Pageable pageable);
}
```

Khi áp dụng cache, code sẽ như sau:

```java
@Cacheable(value = "companies", key = "#clientId + ':' + #name + ':' + #industryName + ':' + #tagName + ':' + #pageable.pageNumber + ':' + #pageable.pageSize + ':' + #pageable.sort")
public PagedResponse<CompanyResponse> getAllCompanies(Long clientId, String name, String industryName, String tagName, Pageable pageable) {
    // Logic to fetch companies from database
}
```

Bạn có thể để trống key, khi đó Spring sẽ tự động tạo key dựa trên tất cả các tham số của phương thức. Tuy nhiên, trong trường hợp này, tôi muốn sử dụng một key cụ thể để dễ quản lý.

## Kết quả sau khi áp dụng Cache

Thử gọi lại các request trước đấy. Khi không có điều kiện lọc, API trả về trong **281ms**. Thay đổi không đáng kể so với trước đó. Nên nhớ, đây là lần đầu tiên gọi API, nên cache vẫn chưa được tạo, đồng thời dữ liệu cần được thêm vào cache. Tuy nhiên, thời gian phản hồi chênh lệch rất nhỏ, chứng tỏ redis thêm dữ liệu vào cache rất nhanh.

Ngạc nhiên là khi gọi lại, thời gian giảm xuống còn **220ms**. Chứng tỏ thời gian truy xuất dữ liệu so sánh giữa database và redis là không đáng kể trong trường hợp này. Có thể nếu số lượng bản ghi tăng lên, thời gian truy xuất sẽ tăng lên, nhưng với số lượng bản ghi hiện tại tôi đang có, khoảng cách này vẫn rất nhỏ.

Thử gọi lại các request với điều kiện lọc. Khi có điều kiện lọc với tag và industry, không ngạc nhiên là thời gian phản hồi vẫn là **3,217ms**. Nhưng khi gọi lại, thời gian giảm xuống còn **287ms**. Giảm gần 10 lần. Điều này cho thấy cache đã hoạt động rất tốt.

Trong Redis, ta có thể thấy 2 record được tạo ra:

```text
127.0.0.1:6379> keys *
1) "companies::1:null:null:null:0:20:id: DESC"
2) "companies::1:null:Industry:Tag:0:20:id: DESC"
```

## Vấn đề Cache Invalidation

Vậy là giải quyết được hết sao? Không hẳn. Dữ liệu company có thể thay đổi. Người dùng có thể thay đổi company, hoặc tag hoặc industry. Khi đó, ta cần phải xóa cache (evict) để đảm bảo dữ liệu luôn được cập nhật mới nhất. Nếu không, người dùng sẽ nhận được dữ liệu cũ từ cache, dẫn đến việc hiển thị thông tin không chính xác.

Có thể dùng `@CacheEvict` để xóa cache khi có thay đổi dữ liệu. Nhưng trường hợp này, tôi sẽ dùng RedistTemplate để các bạn có thể thấy rõ hơn cách hoạt động của cache.

```java
redisTemplate.keys("companies::" + clientId + ":*").forEach(key -> redisTemplate.delete(key));
```

Vấn đề nữa là đặt code này ở đâu? Bên trong các service có liên quan đến việc thay đổi dữ liệu company, tag hoặc industry. Ví dụ, khi người dùng import company, ta cần xóa cache để đảm bảo dữ liệu mới được lấy từ cơ sở dữ liệu sau khi import. Vậy là đặt ở cuối cùng của phương thức import company sẽ như sau:

```java
@Transactional
public void importCompaniesFromFile(Long clientId, MultipartFile file) {
    // Parse the file and create a list of Company entities
    companyRepository.saveAll(companies);
    // Evict caches after import
    cacheEvictionService.evictCompaniesCacheByClientId(clientId);
}
```

## Race Condition với Transaction

Sẽ có rất nhiều bạn làm như vậy, nhưng bạn có thể cần nghĩ lại. Hãy xem kỹ những dòng log bên dưới đây:

```text
2025-08-03T03:08:18.653+07:00 c.l.s.c.s.cache.CacheEvictionService     : Starting cache eviction for companies cache, client ID: 1
2025-08-03T03:08:18.653+07:00 c.l.s.c.s.cache.CacheEvictionService     : Attempting to evict cache entries - Cache: companies, Pattern: 1:*
2025-08-03T03:08:18.654+07:00 c.l.s.c.s.cache.CacheEvictionService     : Searching for Redis keys with pattern: companies::1:*
2025-08-03T03:08:18.654+07:00 o.s.d.redis.core.RedisConnectionUtils    : Fetching Redis Connection from RedisConnectionFactory
2025-08-03T03:08:18.655+07:00 o.s.d.redis.core.RedisConnectionUtils    : Closing Redis Connection
2025-08-03T03:08:18.656+07:00 c.l.s.c.s.cache.CacheEvictionService     : No cache entries found for pattern: companies::1:*
2025-08-03T03:08:18.656+07:00 c.l.s.c.s.cache.CacheEvictionService     : Completed cache eviction for companies cache, client ID: 1
2025-08-03T03:08:18.656+07:00 TRACE 32368 --- [caching-demo] [nio-8081-exec-2] o.s.t.i.TransactionInterceptor           : Completing transaction for [com.luanvv.springboot.cachingdemo.service.cache.CompanyCacheService.importCompaniesFromFile]
2025-08-03T03:08:18.656+07:00 o.s.orm.jpa.JpaTransactionManager        : Initiating transaction commit
2025-08-03T03:08:18.656+07:00 o.s.orm.jpa.JpaTransactionManager        : Committing JPA transaction on EntityManager [SessionImpl(2112965772<open>)]
2025-08-03T03:08:18.769+07:00 o.s.orm.jpa.JpaTransactionManager        : Closing JPA EntityManager [SessionImpl(2112965772<open>)] after transaction
```

Thời điểm 2025-08-03T03:08:18.656+07:00 hoàn thành việc evict cache. Nhưng đến 2025-08-03T03:08:18.769+07:00, việc import company mới thực sự hoàn thành. Tại sao vậy?  
Bởi vì Spring sử dụng proxy để thực hiện các phương thức có annotation `@Transactional`, tức là việc commit transaction sẽ được thực hiện sau khi phương thức hoàn thành. Điều này có nghĩa là việc evict cache sẽ được thực hiện trước khi transaction thực sự được commit vào database, dẫn đến việc cache vẫn còn dữ liệu cũ. Trong khoảng 113ms đó, nếu có request nào đến API, nó sẽ lấy dữ liệu cũ được lưu trong cache, dẫn đến dữ liệu sẽ luôn là cũ. Trường hợp này được coi là race condition và rất khó để phát hiện ra.

## Giải pháp với TransactionalEventListener

Để giải quyết vấn đề này, ta cần đảm bảo rằng cache chỉ được xóa sau khi transaction đã hoàn thành. Để thực hiện điều này, ta có thể sử dụng `@TransactionalEventListener` để lắng nghe sự kiện transaction commit và sau đó thực hiện việc xóa cache.

```java
@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
public void handleTransactionCommit(CompanyUpdatedEvent event) {
    cacheEvictionService.evictCompaniesCacheByClientId(event.clientId());
}
```

Và trong phương thức import company, thay vì evict cache ngay lập tức, ta sẽ publish một sự kiện để lắng nghe và xóa cache sau khi transaction commit.

```java
eventPublisher.publishEvent(new CompanyUpdatedEvent(clientId, null, "IMPORT"));
```

ApplicationEventPublisher trong Spring không phải asynchronous, nhưng việc tích hợp chặt chẽ với transaction sẽ đảm bảo rằng sự kiện này chỉ được xử lý sau khi transaction đã hoàn thành. Điều này có nghĩa là cache sẽ chỉ được xóa sau khi dữ liệu đã được cập nhật trong database, đảm bảo tính nhất quán của dữ liệu.

Cùng thử import lại:

```text
2025-08-03T03:30:16.717+07:00 o.s.orm.jpa.JpaTransactionManager        : Initiating transaction commit
2025-08-03T03:30:16.717+07:00 o.s.orm.jpa.JpaTransactionManager        : Committing JPA transaction on EntityManager [SessionImpl(847734420<open>)]
2025-08-03T03:30:16.761+07:00 c.l.s.c.s.c.CompanyCacheEvictionListener : Handling company IMPORT event for company ID: null after transaction commit
2025-08-03T03:30:16.761+07:00 c.l.s.c.s.c.CompanyCacheEvictionListener : Evicting cache for client ID: 1
2025-08-03T03:30:16.761+07:00 c.l.s.c.s.cache.CacheEvictionService     : Starting cache eviction for companies cache, client ID: 1
2025-08-03T03:30:16.761+07:00 c.l.s.c.s.cache.CacheEvictionService     : Attempting to evict cache entries - Cache: companies, Pattern: 1:*
2025-08-03T03:30:16.761+07:00 c.l.s.c.s.cache.CacheEvictionService     : Searching for Redis keys with pattern: companies::1:*
2025-08-03T03:30:16.761+07:00 o.s.d.redis.core.RedisConnectionUtils    : Fetching Redis Connection from RedisConnectionFactory
2025-08-03T03:30:16.762+07:00 o.s.d.redis.core.RedisConnectionUtils    : Closing Redis Connection
2025-08-03T03:30:16.762+07:00 c.l.s.c.s.cache.CacheEvictionService     : Found 1 keys to evict: [companies::1:null:null:null:0:20:id: DESC]
2025-08-03T03:30:16.762+07:00 c.l.s.c.s.cache.CacheEvictionService     : Successfully evicted 1 entries from companies cache with pattern: 1:*
2025-08-03T03:30:16.762+07:00 c.l.s.c.s.cache.CacheEvictionService     : Completed cache eviction for companies cache, client ID: 1
2025-08-03T03:30:16.762+07:00 o.s.orm.jpa.JpaTransactionManager        : Closing JPA EntityManager [SessionImpl(847734420<open>)] after transaction
```

Lần này việc evict cache được thực hiện sau khi transaction commit. Vấn đề race condition đã được giải quyết.

## Kết luận

Vậy là chúng ta đã giải quyết được vấn đề hiệu suất truy vấn, đồng thời đảm bảo tính nhất quán của dữ liệu.

Có thể bạn sẽ thấy rằng việc sử dụng cache có thể làm tăng độ phức tạp của code một chút. Tuy nhiên, trong trường hợp này, nó thực sự cần thiết để giải quyết vấn đề cấp bách của dự án mà không yêu cầu thay đổi lớn trong kiến trúc.

Vẫn có nhiều vấn đề khác cần giải quyết, như publish event sao cho hợp lý, quản lý size của cache, fallback khi cache không có dữ liệu, v.v. Nhưng đó là câu chuyện của một bài viết khác.

Trên đây là chia sẻ của mình. Hy vọng nó sẽ hữu ích cho những ai đang gặp vấn đề tương tự.

Source code của dự án này có thể tìm thấy tại [github.com/luanvv/spring-boot-caching-demo](https://github.com/luanvv/spring-boot-caching-demo).